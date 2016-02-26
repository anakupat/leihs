steps_for :inspection do

  step 'following requests exist for the current budget period' do |table|
    current_budget_period = Procurement::BudgetPeriod.current
    table.hashes.each do |value|
      n = value['quantity'].to_i
      user = case value['user']
               when 'myself' then @current_user
               else
                 User.find_by(firstname: value['user']) || \
                 begin
                   new_user = create_user(value['user'])
                   FactoryGirl.create :procurement_access,
                                      :requester,
                                      user: new_user
                   new_user
                 end
             end
      group = case value['group']
                when 'inspected'
                  @group
                else
                  nil
              end

      n.times do
        FactoryGirl.create :procurement_request,
                           user: user,
                           group: group,
                           budget_period: current_budget_period
      end
      expect(current_budget_period.requests.where(user_id: user).count).to eq n
    end
  end

  step 'I can not move any request to the old budget period' do
    within '.request', match: :first do
      el = find('.btn-group .fa-gear')
      btn = el.find(:xpath, ".//parent::button//parent::div")
      btn.click unless btn['class'] =~ /open/
      within btn do
        expect(has_no_selector?('a', text: @past_budget_period.to_s)).to be true
      end
    end
  end

  step 'I can not submit the data' do
    find 'button[disabled]', text: _('Save'), match: :first
  end

  step 'I move a request to the future budget period' do
    within '.request', match: :first do
      @request = Procurement::Request.find current_scope['data-request_id']
      el = find('.btn-group .fa-gear')
      btn = el.find(:xpath, ".//parent::button//parent::div")
      btn.click unless btn['class'] =~ /open/
      within btn do
        find('a', text: @future_budget_period.to_s).click
      end
    end

    @changes = {
      budget_period_id: @future_budget_period.id
    }
  end

  step 'I move a request to the other group where I am not inspector' do
    within '.request', match: :first do
      @request = Procurement::Request.find current_scope['data-request_id']
      @other_group = Procurement::Group.where.not(id: @request.group_id) \
        .detect do |group|
          not group.inspectable_by?(@current_user)
      end
      el = find('.btn-group .fa-gear')
      btn = el.find(:xpath, ".//parent::button//parent::div")
      btn.click unless btn['class'] =~ /open/
      within btn do
        find('a', text: @other_group.to_s).click
      end
    end

    @changes = {
        group_id: @other_group.id
    }
  end

  step 'I press on the Userplus icon of a group I am inspecting' do
    within '#filter_target' do
      within '.panel-success .panel-body' do
        within '.row .h4', text: @group.name do
          find('.fa-user-plus').click
        end
      end
    end
  end

  step 'I see both my requests' do
    within '#filter_target' do
      Procurement::Request.where(user_id: @current_user).pluck(:id).each do |id|
        find "[data-request_id='#{id}']"
      end
    end
  end

  step 'several requests exist' do
    n = 3
    n.times do
      FactoryGirl.create :procurement_request
    end
    expect(Procurement::Request.count).to eq n
  end

  step 'templates for my group exist' do
    3.times do
      FactoryGirl.create :procurement_template_category,
                         :with_templates,
                         group: @group
    end
  end

  step 'the changes are saved successfully to the database' do
    @request.reload
    @changes.each_pair do |k,v|
      expect(@request.send(k)).to eq v
    end
  end

  step 'the current budget period is in inspection phase' do
    current_budget_period = Procurement::BudgetPeriod.current
    travel_to_date(current_budget_period.inspection_start_date + 1.day)
    expect(Time.zone.today).to be > current_budget_period.inspection_start_date
    expect(Time.zone.today).to be < current_budget_period.end_date
  end

  step 'the following information is deleted from the request' do |table|
    table.raw.flatten.each do |value|
      case value
        when 'Approved quantity'
          expect(@request.approved_quantity).to be_nil
        when 'Order quantity'
          expect(@request.order_quantity).to be_nil
        when 'Inspection comment'
          expect(@request.inspection_comment).to be_nil
        else
          raise
      end
    end
  end

  step 'the list of requests is adjusted immediately' do
    within '#filter_target' do
      expect(has_no_selector? '.spinner').to be true
    end
  end

  step 'there is a budget period which has already ended' do
    current_budget_period = Procurement::BudgetPeriod.current
    @past_budget_period = FactoryGirl.create :procurement_budget_period,
     inspection_start_date: current_budget_period.inspection_start_date - 2.months,
     end_date: current_budget_period.inspection_start_date - 1.month
  end

  step 'there is a future budget period' do
    current_budget_period = Procurement::BudgetPeriod.current
    @future_budget_period = FactoryGirl.create :procurement_budget_period,
     inspection_start_date: current_budget_period.end_date + 1.month,
     end_date: current_budget_period.end_date + 2.months
  end

end
