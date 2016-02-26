module CommonSteps

  step 'a request created by myself exists' do
    @request = FactoryGirl.create :procurement_request,
                                  user: @current_user,
                                  budget_period: Procurement::BudgetPeriod.current
  end

  step 'I click on save' do
    click_on _('Save'), match: :first
  end

  # step 'I enter the section :section' do |section|
  #   case section
  #     when 'My requests'
  #       step 'I navigate to the requests overview page'
  #     else
  #       raise
  #   end
  # end

  step 'I fill in the following fields' do |table|
    table.raw.flatten.each do |value|
      case value
        when 'Price'
          find("input[name*='[price]']").set 123
        when 'Requested quantity', 'Approved quantity'
          fill_in _(value), with: 2
        when 'Replacement / New'
          find("input[name*='[replacement]'][value='1']").click
        else
          fill_in _(value), with: Faker::Lorem.sentence
      end
    end
  end

  step 'I see a success message' do
    #expect(page).to have_content _('Saved')
    find '.flash .alert-success', match: :first
  end

  step 'I see an error message' do
    find '.flash .alert-danger', match: :first
  end

  step 'I see the amount of requests which are listed is :n' do |n|
    within '#filter_target' do
      find 'h4', text: /^#{n} #{_('Requests')}$/
    end
  end

  step 'I see the headers of the columns of the overview' do
    find '#column-titles'
  end

  step 'I want to create a new request' do
    step 'there exists a procurement group'
    step 'I navigate to the requests overview page'

    # within '.panel-success .panel-heading',
    #        text: Procurement::BudgetPeriod.current.name do
    #   find('i.fa-plus-circle').click
    # end
    # within '.panel-body .col-sm-6', text: _('Create request for specific group') do
    #   find('a', text: Procurement::Group.first.name).click
    # end
    # within '.sidebar-wrapper' do
    #   find('i.fa-plus-circle').click
    # end
    within '.panel-success .panel-body' do
      within  '.row .h4', text: Procurement::Group.first.name do
        find('i.fa-plus-circle').click
      end
    end
  end

  step ':count groups exist' do |count|
    n = case count
          when 'several'
            3
          else
            count.to_i
        end
    @groups = []
    n.times do
      @groups << FactoryGirl.create(:procurement_group)
    end
  end

  step 'page has been loaded' do
    expect(has_no_selector?(".spinner")).to be true
  end

  step 'the current budget period exist' do
    FactoryGirl.create(:procurement_budget_period)
  end

  step 'the current date is after the budget period end date' do
    travel_to_date @request.budget_period.end_date + 1.day
    expect(Time.zone.today).to be > @request.budget_period.end_date
  end
  #alias
  step 'the budget period has ended' do
    step 'the current date is after the budget period end date'
  end

  step 'the field :field is marked red' do |field|
    within all('form table tbody tr').last do
      input_field = case field
                      when 'requester name', 'name'
                        find("input[name*='[name]']")
                      when 'department'
                        find("input[name*='[department]']")
                      when 'organization'
                        find("input[name*='[organization]']")
                      when 'inspection start date'
                        find("input[name*='[inspection_start_date]']")
                      when 'end date'
                        find("input[name*='[end_date]']")
                    end
      expect(input_field['required']).to eq 'true' # ;-)
    end
  end

  step 'there exists a procurement group' do
    @group = Procurement::Group.first || FactoryGirl.create(:procurement_group)
  end

  def visit_request(request)
    visit procurement.group_budget_period_user_requests_path(request.group,
                                                             request.budget_period,
                                                             request.user)
  end

  def travel_to_date(datetime = nil)
    if datetime
      Timecop.travel datetime
    else
      Timecop.return
    end

    # The minimum representable time is 1901-12-13, and the maximum representable time is 2038-01-19
    ActiveRecord::Base.connection.execute \
    "SET TIMESTAMP=unix_timestamp('#{Time.now.iso8601}')"
    mysql_now = ActiveRecord::Base.connection \
    .exec_query('SELECT CURDATE()').rows.flatten.first
    raise 'MySQL current datetime has not been changed' if mysql_now != Date.today
  end

  def currency(amount)
    ActionController::Base.helpers.number_to_currency(
        amount,
        unit: Setting.local_currency_string,
        precision: 0)
  end

end

RSpec.configure { |c| c.include CommonSteps }
