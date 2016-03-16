module Procurement
  module Csv
    extend ActiveSupport::Concern

    included do
      def self.csv_export(requests, current_user)
        require 'csv'

        objects = []
        requests.each do |request|
          show_all = (not request.budget_period.in_requesting_phase?) \
                      or request.group.inspectable_or_readable_by?(current_user)
          objects << {
            _('Budget period') => request.budget_period,
            _('Group') => request.group,
            _('Requester') => request.user,
            _('Organisation unit') => request.organization.name_with_parent,
            _('Article / Project') => request.article_name,
            _('Article nr. / Producer nr.') => request.article_number,
            _('Supplier') => request.supplier_name,
            _('Requested quantity') => request.requested_quantity,
            _('Approved quantity') => if show_all
                                        request.approved_quantity
                                      end,
            _('Order quantity') => if show_all
                                     request.order_quantity
                                   end,
            format('%s %s', _('Price'), _('incl. VAT')) => request.price,
            format('%s %s', _('Total'), _('incl. VAT')) => \
                                              request.total_price(current_user),
            _('State') => _(request.state(current_user).to_s.humanize),
            _('Priority') => request.priority,
            _('Article nr. / Producer nr.') => request.article_number,
            format('%s / %s', _('Replacement'), _('New')) => if request.replacement
                                                                 _('Replacement')
                                                             else
                                                               _('New')
                                                             end,
            _('Receiver') => request.receiver,
            _('Point of Delivery') => request.location_name,
            _('Motivation') => request.motivation,
            _('Inspection comment') => if show_all
                                         request.inspection_comment
                                       end
          }
        end

        csv_header = objects.flat_map(&:keys).uniq

        CSV.generate(col_sep: ';',
                     quote_char: "\"",
                     force_quotes: true,
                     headers: :first_row) do |csv|
          csv << csv_header
          objects.each do |object|
            csv << csv_header.map { |h| object[h] }
          end
        end
      end
    end

  end
end
