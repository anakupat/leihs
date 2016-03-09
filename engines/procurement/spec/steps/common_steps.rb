module CommonSteps

  step 'a receiver exists' do
    FactoryGirl.create :user
  end

  step 'a request with following data exist' do |table|
    @changes = {
        group: @group
    }
    table.hashes.each do |hash|
      case hash['key']
        when 'budget period'
          @changes[:budget_period] = if hash['value'] == 'current'
                                       Procurement::BudgetPeriod.current
                                     else
                                       Procurement::BudgetPeriod.all.sample
                                     end
        when 'user'
          @changes[:user] = case hash['value']
                              when 'myself'
                                @current_user
                              else
                                find_or_create_user(hash['value'], true)
                            end
        when 'requested amount'
          @changes[:requested_quantity] = hash['value'].to_i
        when 'approved amount'
          @changes[:approved_quantity] = hash['value'].to_i
        when 'inspection comment'
          @changes[:inspection_comment] = case hash['value']
                                            when 'random'
                                              Faker::Lorem.sentence
                                            else
                                              hash['value']
                                          end
        else
          raise
      end
    end
    @request = FactoryGirl.create :procurement_request, @changes
  end

  step 'for each request I see the following information' do |table|
    elements = all('[data-request_id]', minimum: 1)
    expect(elements).not_to be_empty
    elements.each do |element|
      request = Procurement::Request.find element['data-request_id']
      within element do
        table.raw.flatten.each do |value|
          case value
            when 'article name'
              find '.col-sm-2', text: request.article_name
            when 'name of the requester'
              find '.col-sm-2', text: request.user.to_s
            when 'department'
              find '.col-sm-2', text: request.organization.parent.to_s
            when 'organisation'
              find '.col-sm-2', text: request.organization.to_s
            when 'price'
              find '.col-sm-1 .total_price', text: request.price.to_i
            when 'requested amount'
              within all('.col-sm-2.quantities div', count: 3)[0] do
                expect(page).to have_content request.requested_quantity
              end
            when 'approved amount'
              within all('.col-sm-2.quantities div', count: 3)[1] do
                expect(page).to have_content request.approved_quantity
              end
            when 'order amount'
              within all('.col-sm-2.quantities div', count: 3)[2] do
                expect(page).to have_content request.order_quantity
              end
            when 'total amount'
              find '.col-sm-1 .total_price',
                   text: request.total_price(@current_user).to_i
            when 'priority'
              find '.col-sm-1', text: _(request.priority.capitalize)
            when 'state'
              state = request.state(@current_user)
              find '.col-sm-1', text: _(state.to_s.humanize)
            else
              raise
          end
        end
      end
    end
  end

  step 'I choose the following :field value' do |field, table|
    within '.request[data-request_id="new_request"]' do
      label = case field
                when 'priority'
                  _('Priority')
                when 'replacement'
                  "%s / %s" % [_('Replacement'), _('New')]
                else
                  raise
              end
      within '.form-group', text: label do
        table.raw.flatten.each do |value|
          choose _(value)
        end
      end
    end
  end
  # alias
  step 'I can choose the following :field values' do |field, table|
    step "I choose the following #{field} value", table
  end

  step 'I choose the name of a receiver' do
    @receiver = User.not_as_delegations.where.not(id: @current_user).sample

    # find('.form-group', text: _('Name of receiver')). \
    #   find('input').set @receiver.to_s
    fill_in _('Name of receiver'), with: @receiver.name
    #not working#
    # within '.ui-autocomplete' do
    #   find('.ui-menu-item', text: @receiver.name).click
    # end
  end

  step 'I choose the point of delivery' do
    @location = Location.all.sample

    fill_in _('Point of Delivery'), with: @location.to_s
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

  step 'I delete the following fields' do |table|
    el1, el2 = if @template
                 ['.panel-collapse.in',
                 find(:xpath,
                      "//input[@value='#{@template.article_name}']/ancestor::tr")]
               elsif @request
                 ['.panel-body',
                  ".request[data-request_id='#{@request.id}']"]
               else
                 ['.panel-body',
                  ".request[data-request_id='new_request']"]
               end

    within el1 do
      within el2 do
        table.raw.flatten.each do |value|
          case value
            when 'Price'
              find("input[name*='[price]']").set ''
            else
              fill_in _(value), with: ''
          end
        end
      end
    end
  end

  step 'I fill in all mandatory information' do
    @changes = {}
    request_el = if @template
           ".request[data-template_id='#{@template.id}']"
         else
           ".request[data-request_id='new_request']"
         end
    within request_el do
      all('[data-to_be_required]', minimum: 1).each do |el|
        key = el['name'].match(/.*\[(.*)\]\[(.*)\]/)[2]

        case key
          when 'requested_quantity'
            el.set v = Faker::Number.number(2).to_i
          when 'replacement'
            find("input[name*='[replacement]'][value='#{v = 1}']").click
          else
            el.set v = Faker::Lorem.sentence
        end

        @changes[key.to_sym] = v
      end
    end
  end

  step 'I fill in the following fields' do |table|
    @changes ||= {}
    table.hashes.each do |hash|
      hash['value'] = nil if hash['value'].blank?
      case hash['key']
        when 'Price'
          v = (hash['value'] || Faker::Number.number(4)).to_i
          find("input[name*='[price]']").set v
        when /quantity/
          v = (hash['value'] || Faker::Number.number(2)).to_i
          fill_in _(hash['key']), with: v
        when 'Replacement / New'
          v = hash['value'] || 1
          find("input[name*='[replacement]'][value='#{v}']").click
        else
          v = hash['value'] || Faker::Lorem.sentence
          fill_in _(hash['key']), with: v
      end
      @changes[mapped_key(hash['key'])] = v

      # NOTE trigger change event
      find('body').native.send_keys(:tab) #find('body').click
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

  step 'I :boolean a success message' do |boolean|
    if boolean
      #expect(page).to have_content _('Saved')
      find '.flash .alert-success', match: :first
    else
      expect(page).not_to have_selector '.flash .alert-success'
    end
  end

  step 'I see an error message' do
    find '.flash .alert-danger', match: :first
  end

  step 'I see all groups' do
    within '.panel-success .panel-body' do
      Procurement::Group.all.each do |group|
        find'.row', text: group.name
      end
    end
  end
  # not alias, but same implementation
  step 'I see all groups listed' do
    step 'I see all groups'
  end

  step 'I see the amount of requests listed' do
    within '#filter_target' do
      find 'h4', text: /^\d #{_('Requests')}$/
    end
  end

  step 'I see the amount of requests which are listed is :n' do |n|
    within '#filter_target' do
      find 'h4', text: /^#{n} #{_('Requests')}$/
    end
  end

  step 'I see the current budget period' do
    find '.panel-success > .panel-heading .h4',
         text: Procurement::BudgetPeriod.current.name
  end
  # alias
  step 'I see the budget period' do
    step 'I see the current budget period'
  end

  step 'I see the headers of the columns of the overview' do
    find '#column-titles'
  end

  step 'I see the requested amount per budget period' do
    requests = Procurement::BudgetPeriod.current.requests
                .where(group_id: displayed_groups)
    requests = requests.where(user_id: @current_user) if filtered_own_requests?
    total = requests.map { |r| r.total_price(@current_user) }.sum
    find '.panel-success > .panel-heading .label-primary.big_total_price',
         text: number_with_delimiter(total.to_i)
  end

  step 'I see the requested amount per group of each budget period' do
    displayed_groups.each do |group|
      requests = Procurement::BudgetPeriod.current.requests
                     .where(group_id: group)
      requests = requests.where(user_id: @current_user) if filtered_own_requests?
      total = requests.map { |r| r.total_price(@current_user) }.sum
      within '.panel-success .panel-body' do
        within '.row', text: group.name do
          find '.label-primary.big_total_price',
            text: number_with_delimiter(total.to_i)
        end
      end
    end
  end

  step 'I see when the requesting phase of this budget period ends' do
    within '.panel-success > .panel-heading' do
      find '.row',
           text: _('requesting phase until %s') \
                  % I18n.l(Procurement::BudgetPeriod.current.inspection_start_date)
    end
  end

  step 'I see when the inspection phase of this budget period ends' do
    within '.panel-success > .panel-heading' do
      find '.row',
           text: _('inspection phase until %s') \
                  % I18n.l(Procurement::BudgetPeriod.current.end_date)
    end
  end

  step 'I upload a file' do
    field = find "input[name*='[attachments_attributes][][file]']"
    attach_file(field[:name], #_('Attachments'),
                "#{Rails.root}/features/data/images/image1.jpg")
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
    expect(page).to have_no_selector '.spinner'
  end

  step 'several budget periods exist' do
    current_year = Time.zone.today.year
    @budget_periods = []
    (1..3).each do |num|
      @budget_periods << \
        FactoryGirl.create(
          :procurement_budget_period,
          name: current_year + num,
          inspection_start_date: Date.new(current_year + num, 1, 1),
          end_date: Date.new(current_year + num, 1, 2)
      )
    end
  end

  step 'several template categories exist' do
    h = {}
    h[:group] = @group if @group
    3.times do
      FactoryGirl.create :procurement_template_category, h
    end
  end

  step 'several template articles in categories exist' do
    Procurement::TemplateCategory.all.each do |category|
      @category = category
      step 'the template category contains articles'
    end
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
    el = if @request
           ".request[data-request_id='#{@request.id}']"
         else
           all('form table tbody tr', minimum: 1).last
         end
    within el do
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
                      when 'inspection comment'
                        find("input[name*='[inspection_comment]']")
                    end
      expect(input_field['required']).to eq 'true' # ;-)
    end
  end

  step 'the request with all given information ' \
       'was created successfully in the database' do
    user = @user || @current_user
    if price = @changes.delete(:price)
      @changes[:price_cents] = price * 100
    end
    expect(@group.requests.where(user_id: user).find_by(@changes)).to be
  end

  step 'the status is set to :state' do |state|
    within '.form-group', text: _('State') do
      find '.label', text: _(state)
    end
  end

  step 'the template category contains articles' do
    3.times do
      FactoryGirl.create :procurement_template,
                         template_category: @category
    end
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

  def mapped_key(from)
    case from
      when 'Article'
        :article_name
      when 'Article nr. / Producer nr.'
        :article_number
      when 'Replacement / New'
        :replacement
      when 'Supplier'
        :supplier_name
      else
        from.parameterize.underscore.to_sym
    end
  end

  def number_with_delimiter(n)
    ActionController::Base.helpers.number_with_delimiter(n)
  end

  private

  def displayed_groups
    Procurement::Group.where(name: all('div.row .h4', minimum: 0).map(&:text))
  end

  def filtered_own_requests?
    Procurement::Access.requesters.where(user_id: @current_user).exists? and \
      (has_no_selector?('#filter_panel input[name="user_id"]') or \
        find('#filter_panel input[name="user_id"]').checked?)
  end

end

RSpec.configure { |c| c.include CommonSteps }
