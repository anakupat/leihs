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

  step 'I fill in all mandatory information' do
    # TODO also for template
    @data = {}
    within ".request[data-request_id='new_request']" do
      all('[data-to_be_required]').each do |el|
        key = el['name'].match(/.*\[(.*)\]\[(.*)\]/)[2]

        case key
          when 'requested_quantity'
            el.set @data[el[key]] = Faker::Number.number(2).to_i
          when 'replacement'
            find("input[name*='[replacement]'][value='#{@data[el[key]] = 1}']").click
          else
            el.set @data[el[key]] = Faker::Lorem.sentence
        end
      end
    end
  end

  step 'I fill in the following fields' do |table|
    @data = {}
    table.raw.flatten.each do |value|
      case value
        when 'Price'
          @price = Faker::Number.number(4).to_i
          find("input[name*='[price]']").set @data[value] = @price
        when 'Requested quantity', 'Approved quantity'
          @quantity = Faker::Number.number(2).to_i
          fill_in _(value), with: @data[value] = @quantity
        when 'Replacement / New'
          find("input[name*='[replacement]'][value='#{@data[value] = 1}']").click
        else
          fill_in _(value), with: @data[value] = Faker::Lorem.sentence
      end
    end
  end

  step 'I press on the plus icon of a group' do
    @group ||= Procurement::Group.first.name
    within '#filter_target' do
      within '.panel-success .panel-body' do
        within '.row .h4', text: @group.name do
          find('i.fa-plus-circle').click
        end
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
    step 'I navigate to the requests overview page'
    step 'I press on the plus icon of a group'
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
  # alias
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

  step 'the request with all given information ' \
       'was created successfully in the database' do
    user = @user || @current_user
    expect(@group.requests.where(user_id: user).find_by(mapped_data)).to be
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

  def mapped_data
    h = {}
    h[:article_name] = @data['Article'] if @data['Article']
    if @data['Article nr. / Producer nr.']
      h[:article_number] = @data['Article nr. / Producer nr.']
    end
    h[:price_cents] = @data['Price'] * 100 if @data['Price']
    h[:supplier_name] = @data['Supplier'] if @data['Supplier']
    if @data['Requested quantity']
      h[:requested_quantity] = @data['Requested quantity']
    end
    h[:motivation] = @data['Motivation'] if @data['Motivation']
    h[:replacement] = @data['Replacement'] if @data['Replacement']
    h
  end

end

RSpec.configure { |c| c.include CommonSteps }
