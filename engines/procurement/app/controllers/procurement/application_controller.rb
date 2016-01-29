module Procurement
  class ApplicationController < ActionController::Base
    include MainHelpers
    include Pundit

    before_action except: :root do
      ApplicationPolicy.new current_user
    end

    rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

    before_action :require_admins, except: :root

    def root
      if not BudgetPeriod.current
        flash.now[:error] = _('Current budget period not defined yet')
        redirect_to budget_periods_path if procurement_admin?
      elsif current_user \
        and Procurement::Group.inspector_of_any_group_or_admin?(current_user)
        redirect_to overview_requests_path
      elsif procurement_requester?
        redirect_to overview_user_requests_path(current_user)
      end
    end

    protected

    helper_method :procurement_admin?, :procurement_requester?

    def procurement_admin?
      current_user and (Access.admin?(current_user) \
        or (Access.admins.empty? and admin?))
    end

    def procurement_requester?
      current_user and Access.requesters.where(user_id: current_user).exists?
    end

    private

    def user_not_authorized(exception)
      flash[:error] = _(exception.message)
      redirect_to root_path
    end

    def require_admins
      if Access.admins.empty?
        flash[:error] = _('No admins defined yet')
        if procurement_admin?
          redirect_to users_path
        else
          redirect_to root_path
        end
      end
    end
  end
end
