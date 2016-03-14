steps_for :csv do

  step 'I export the shown information' do
    # NOTE not really downloading the file, but invoking directly the model class method

    within '.sidebar-wrapper' do
      # click_on _('CSV Export')
      expect(page).to have_selector 'button', text: _('CSV Export')
    end
  end

  step 'the following fields are exported' do |table|
    # NOTE not really downloading the file, but invoking directly the model class method

    client_ids = all('[data-request_id]', minimum: 1).map do |el|
      el['data-request_id'].to_i
    end
    requests = Procurement::Request.find client_ids

    require 'csv'
    @csv = CSV.parse Procurement::Request.csv_export(requests, @current_user),
                     {col_sep: ';',
                      quote_char: "\"",
                      force_quotes: true,
                      headers: :first_row}
    headers = @csv.headers

    table.raw.flatten.each do |value|
      expect(headers).to include case value
                                   when 'Replacement / New'
                                     '%s / %s' % [_('Replacement'), _('New')]
                                   when 'Price'
                                     '%s %s' % [_('Price'), _('incl. VAT')]
                                   when 'Total'
                                     '%s %s' % [_('Total'), _('incl. VAT')]
                                   else
                                    _(value)
                                 end
    end

    expect(@csv.count).to eq requests.count
  end
end
