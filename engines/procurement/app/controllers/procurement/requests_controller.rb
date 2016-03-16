require_dependency 'procurement/application_controller'
require_dependency 'procurement/concerns/filter'

module Procurement
  class RequestsController < ApplicationController
    include Filter

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
      h = { budget_period_id: @budget_period }
      h[:user_id] = @user if @user
      h[:group_id] = @group if @group
      @requests = Request.where h

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
        format.html { default_filters }
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
            r.attachments.destroy(k) if v == '1'
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
      @request = Request.where(user_id: @user, group_id: @group,
                               budget_period_id: @budget_period).find(params[:id])
      h = { inspection_comment: nil, approved_quantity: nil, order_quantity: nil }
      if params[:to_group_id]
        h[:group] = Procurement::Group.find(params[:to_group_id])
      elsif params[:to_budget_period_id]
        h[:budget_period] = BudgetPeriod.find(params[:to_budget_period_id])
      end

      if @request.update_attributes h
        render partial: 'layouts/procurement/flash',
               locals: { flash: { success: _('Request moved') } }
      else
        render status: :bad_request
      end
    end

    def destroy
      request = Request.where(user_id: @user, group_id: @group,
                              budget_period_id: @budget_period).find(params[:id])
      request.destroy
      if request.destroyed?
        render partial: 'layouts/procurement/flash',
               locals: { flash: { success: _('Deleted') } }
      else
        render status: :bad_request
      end
    end

  end
end
