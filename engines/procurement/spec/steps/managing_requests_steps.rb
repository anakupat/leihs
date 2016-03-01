steps_for :managing_requests do

  step 'a new request line is added' do
    find '.request[data-request_id="new_request"]', visible: true
  end

  step 'an email for a group exists' do
    @group = FactoryGirl.create :procurement_group,
                                email: Faker::Internet.email
  end

  step 'I can change the budget period of my request' do
    request = get_current_request @current_user
    visit_request(request)
    next_budget_period = Procurement::BudgetPeriod. \
        where("end_date > ?", request.budget_period.end_date).first

    within ".request[data-request_id='#{request.id}']" do
      el = find('.btn-group .fa-gear')
      btn = el.find(:xpath, ".//parent::button//parent::div")
      btn.click unless btn['class'] =~ /open/
      within btn do
        click_on next_budget_period.name
      end
    end

    expect(page).to have_content _('Request moved')
    expect(request.reload.budget_period_id).to be next_budget_period.id
  end

  step 'I can change the procurement group of my request' do
    request = get_current_request @current_user
    visit_request(request)
    other_group = Procurement::Group.where.not(id: request.group_id).first

    within ".request[data-request_id='#{request.id}']" do
      el = find('.btn-group .fa-gear')
      btn = el.find(:xpath, ".//parent::button//parent::div")
      btn.click unless btn['class'] =~ /open/
      within btn do
        click_on other_group.name
      end
    end

    expect(page).to have_content _('Request moved')
    expect(request.reload.group_id).to be other_group.id
  end

  step 'I can choose the following :field values' do |field, table|
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

  step 'I can delete my request' do
    @request = get_current_request @current_user
    visit_request(@request)

    step 'I delete the request'

    expect(page).to have_content _('Deleted')
    expect{@request.reload}.to raise_error ActiveRecord::RecordNotFound
  end

  step 'I can modify my request' do
    request = get_current_request @current_user
    visit_request(request)

    text = Faker::Lorem.sentence
    within ".request[data-request_id='#{request.id}']" do
      fill_in _('Motivation'), with: text
    end

    step 'I click on save'
    step 'I see a success message'
    expect(request.reload.motivation).to eq text
  end

  step 'I choose a group' do
    @group ||= Procurement::Group.first.name
    within '.panel-success .panel-body' do
      click_on @group.name
    end
  end

  step 'I click on choice :choice' do |choice|
    case choice
      when 'yes'
        page.driver.browser.switch_to.alert.accept
      when 'no'
        page.driver.browser.switch_to.alert.dismiss
      else
        raise
    end
  end

  step 'I click on the email icon' do
    within '.panel-success .panel-heading' do
      find('.fa-envelope').click
    end
  end

  step 'I delete the attachment' do
    within '.form-group', text: _('Attachments') do
      find('.fa-trash', match: :first).click
    end
  end

  step 'I delete the request' do
    within ".request[data-request_id='#{@request.id}']" do
      el = find('.btn-group .fa-gear')
      btn = el.find(:xpath, ".//parent::button//parent::div")
      btn.click unless btn['class'] =~ /open/
      within btn do
        click_on _('Delete')
      end
    end
  end

  step 'I do not see the budget limits' do
    within '.panel-success .panel-body' do
      displayed_groups.each do |group|
        within '.row', text: group.name do
          expect(page).to have_no_selector '.budget_limit'
        end
      end
    end
  end

  step 'I do not see the percentage signs' do
    within '.panel-success .panel-body' do
      displayed_groups.each do |group|
        within '.row', text: group.name do
          expect(page).to have_no_selector '.progress-radial'
        end
      end
    end
  end

  step 'I enter the requested amount' do
    within '.request[data-request_id="new_request"]' do
      @price = Faker::Number.number(4).to_i
      @quantity = Faker::Number.number(2).to_i
      within '.form-group', text: _('Item price') do
        find('input').set @price
      end
      fill_in _('Requested quantity'), with: @quantity
    end
  end

  step 'I open the request' do
    find(".list-group-item[data-request_id='#{@request.id}']").click
  end

  step 'I press on the plus icon of the budget period' do
    within '#filter_target' do
      within '.panel-success .panel-heading' do
        find('i.fa-plus-circle').click
      end
    end
  end

  step 'I press on the plus icon on the left sidebar' do
    within '.sidebar-wrapper' do
      find('i.fa-plus-circle').click
    end
  end

  step 'I receive a message asking me if I am sure I want to delete the data' do
    # page.driver.browser.switch_to.alert.accept
    page.driver.browser.switch_to.alert
  end

  step 'only my requests are shown' do
    elements = all('[data-request_id]')
    expect(elements).not_to be_empty
    elements.each do |element|
      request = Procurement::Request.find element['data-request_id']
      expect(request.user_id).to eq @current_user.id
    end
  end

  step 'no requests exist' do
    Procurement::Request.destroy_all
    expect(Procurement::Request.count).to be_zero
  end

  step 'several points of delivery exist' do
    3.times do
      FactoryGirl.create :location
    end
  end

  step 'several requests created by myself exist' do
    n = 3
    n.times do
      FactoryGirl.create :procurement_request,
                         user: @current_user,
                         budget_period: Procurement::BudgetPeriod.current
    end
    expect(Procurement::Request.where(user_id: @current_user,
                                      budget_period_id: Procurement::BudgetPeriod.current).count).to eq n
  end

  step 'the amount and the price are multiplied and the result is shown' do
    within '.request[data-request_id="new_request"]' do
      total = @price * @quantity
      expect(find('.label.label-primary.total_price').text).to eq currency(total)
    end
  end

  step 'the attachment is deleted successfully from the database' do
    expect(@request.reload.attachments).to be_empty
  end

  step 'the current date has not yet reached the inspection start date' do
    travel_to_date Procurement::BudgetPeriod.current.inspection_start_date - 1.day
    expect(Time.zone.today).to be < \
      Procurement::BudgetPeriod.current.inspection_start_date
  end

  step 'the :field value :value is set by default' do |field, value|
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
        within 'label', text: /^#{_(value)}$/ do
          find("input[type='radio']:checked")
        end
      end
    end
  end

  step 'the request includes an attachment' do
    @request.update_attributes(attachments_attributes:
        [{file: File.open('features/data/images/image1.jpg')}] )
  end

  step 'the request is :result in the database' do |result|
    case result
      when 'successfully deleted'
        step 'I see a success message'
        expect { @request.reload }.to raise_error ActiveRecord::RecordNotFound
      when 'not deleted'
        expect(@request.reload).not_to be_nil
      else
        raise
    end
  end

  private

  def get_current_request(user)
    Procurement::Request.find_by user_id: user.id,
                                 budget_period_id: Procurement::BudgetPeriod.current
  end

end
