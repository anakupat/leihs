require_dependency 'procurement/application_controller'

module Procurement
  class RequestsController < ApplicationController

    before_action do
      if Procurement::Group.inspector_of_any_group_or_admin?(current_user)
        @user = User.not_as_delegations.find(params[:user_id]) if params[:user_id]
      else # only requester
        @user = current_user
      end

      @group = Procurement::Group.find(params[:group_id]) if params[:group_id]
      @budget_period = \
        BudgetPeriod.find(params[:budget_period_id]) if params[:budget_period_id]

      unless RequestPolicy.new(current_user, request_user: @user).allowed?
        raise Pundit::NotAuthorizedError
      end
    end

    def index
      @requests = Request.all
      @requests = @requests.where(user_id: @user) if @user
      @requests = @requests.where(group_id: @group) if @group
      @requests = @requests.where(budget_period_id: @budget_period)

      respond_to do |format|
        format.html
        format.csv do
          send_data Request.csv_export(@requests, current_user),
                    type: 'text/csv; charset=utf-8; header=present',
                    disposition: 'attachment; filename=requests.csv'
        end
      end
    end

    def overview
      respond_to do |format|
        format.html do
          default_filters
        end
        format.js do
          @h = get_requests
          render partial: 'overview'
        end
        format.csv do
          requests = get_requests.values.flatten
          send_data Request.csv_export(requests, current_user),
                    type: 'text/csv; charset=utf-8; header=present',
                    disposition: 'attachment; filename=requests.csv'
        end
      end
    end

    def new
      authorize @budget_period, :not_past?
      @template_categories = TemplateCategory.all
      @groups = Procurement::Group.all
    end

    def create
      keys = [:article_name, :model_id, :article_number, :price, :supplier_name,
              :supplier_id, :motivation, :receiver, :location_name, :location_id,
              :template_id, attachments_attributes: [:file]]
      keys += [:approved_quantity,
               :order_quantity,
               :inspection_comment] if @group.inspectable_by?(current_user)

      errors = params.require(:requests).values.map do |param|
        to_permit_keys = if param[:id].blank? or @user == current_user
                           keys + [:requested_quantity, :priority, :replacement]
                         else
                           keys
                         end
        permitted = param.permit(to_permit_keys)

        if param[:id]
          r = Request.find(param[:id])
          param[:attachments_delete].each_pair do |k, v|
            if v == '1'
              r.attachments.destroy(k)
            end
          end if param[:attachments_delete]
          if permitted.values.all?(&:blank?)
            r.destroy
          else
            r.update_attributes(permitted)
          end
        else
          next if permitted[:motivation].blank?
          r = @group.requests.create(permitted) do |x|
            x.user = @user
            x.budget_period = @budget_period
          end
        end
        r.errors.full_messages
      end.flatten.compact

      if errors.empty?
        flash[:success] = _('Saved')
        head status: :ok
      else
        render json: errors, status: :internal_server_error
      end
    end

    def move
      @request = Request.where(user_id: @user,
                               group_id: @group,
                               budget_period_id: @budget_period).find(params[:id])
      h = { inspection_comment: nil, approved_quantity: nil, order_quantity: nil }
      if params[:to_group_id]
        h.merge!(group: Procurement::Group.find(params[:to_group_id]))
      elsif params[:to_budget_period_id]
        h.merge!(budget_period: BudgetPeriod.find(params[:to_budget_period_id]))
      end

      if @request.update_attributes h
        render partial: 'layouts/procurement/flash',
               locals: { flash: { success: _('Request moved') } }
      else
        render status: :bad_request
      end
    end

    def destroy
      request = Request.where(user_id: @user,
                              group_id: @group,
                              budget_period_id: @budget_period) \
                       .find(params[:id])
      request.destroy
      if request.destroyed?
        render partial: 'layouts/procurement/flash',
               locals: { flash: { success: _('Deleted') } }
      else
        render status: :bad_request
      end
    end

    private

    def default_filters
      @filter = params[:filter] || begin
        r = session[:requests_filter] || {}
        r.delete('search') # NOTE reset on each request
        r
      end
      @filter['user_id'] ||= @user.id if @user
      @filter['budget_period_ids'] ||= [Procurement::BudgetPeriod.current.id]
      @filter['group_ids'] ||= begin
        r = Procurement::GroupInspector.where(user_id: current_user) \
            .pluck(:group_id)
        r = Procurement::Group.pluck(:id) if r.empty?
        r
      end
      @filter['priorities'] ||= ['high', 'normal']
      @filter['states'] ||= Procurement::Request::STATES

      @filter['sort_by'] = 'state' if @filter['sort_by'].blank?
      @filter['sort_dir'] = 'asc' if @filter['sort_dir'].blank?
    end

    def fallback_filters
      @filter = params[:filter]

      @filter['user_id'] = @user.id if @user

      @filter['budget_period_ids'] ||= []
      @filter['budget_period_ids'].delete('multiselect-all')

      @filter['group_ids'] ||= []
      if @filter['organization_id'].blank?
        @filter['organization_id'] = nil
      end
      @filter['priorities'] ||= []
      @filter['states'] ||= []
      session[:requests_filter] = @filter
    end

    def get_requests
      fallback_filters
      h = {}
      Procurement::BudgetPeriod.order(end_date: :desc) \
          .find(@filter['budget_period_ids']).each do |budget_period|

        requests = budget_period.requests.search(@filter['search']) \
                      .where(group_id: @filter['group_ids'],
                             priority: @filter['priorities'])
        requests = requests.where(user_id: @user) if @user
        if @filter['organization_id']
          requests = requests.joins(:organization)
                         .where(['organization_id = :id OR ' \
                                 'procurement_organizations.parent_id = :id',
                                 { id: @filter['organization_id'] }])
        end
        requests = requests.select do |r|
          @filter['states'] \
                        .map(&:to_sym).include? r.state(current_user)
        end

        requests = requests.sort do |a, b|
          case @filter['sort_by']
          when 'total_price'
              a.total_price(current_user) <=> b.total_price(current_user)
          when 'state'
              Request::STATES.index(a.state(current_user)) <=> \
                Request::STATES.index(b.state(current_user))
          when 'department'
              a.organization.parent.to_s.downcase <=> \
                b.organization.parent.to_s.downcase
          when 'article_name', 'user'
              a.send(@filter['sort_by']).to_s.downcase <=> \
                b.send(@filter['sort_by']).to_s.downcase
          else
              a.send(@filter['sort_by']) <=> \
                b.send(@filter['sort_by'])
          end
        end
        requests.reverse! if @filter['sort_dir'] == 'desc'

        h[budget_period] = requests
      end
      h
    end

  end
end
