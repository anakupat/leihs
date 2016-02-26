steps_for :templates do

  step 'a template category exists' do
    @category = FactoryGirl.create :procurement_template_category,
                                   group: @group
  end

  step 'I delete an article from the category' do
    @template = @category.templates.first
    within '.panel-collapse.in' do
      within(:xpath, "//input[@value='#{@template.article_name}']/ancestor::tr") do
        find('i.fa-minus-circle').click
      end
    end
  end

  step 'I delete the following fields' do |table|
    within '.panel-collapse.in' do
      within(:xpath, "//input[@value='#{@template.article_name}']/ancestor::tr") do
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

  step 'I delete the template category' do
    within(:xpath, "//input[@value='#{@category.name}']/ancestor::" \
                   "div[contains(@class, 'panel-heading')]") do
      find('i.fa-minus-circle').click
    end
  end

  step 'I edit the category' do
    find("input[value='#{@category.name}']").click
  end

  step 'I enter the category name' do
    @name = Faker::Lorem.sentence
    within @el do
      fill_in _('Category'), with: @name
    end
  end

  step 'I modify the category name' do
    @el = find(:xpath, "//input[@value='#{@category.name}']/ancestor::" \
                       "div[contains(@class, 'panel-heading')]")
    step 'I enter the category name'
  end

  step 'several template categories exist' do
    3.times do
      FactoryGirl.create :procurement_template_category,
                         group: @group
    end
  end

  step 'several articles in categories exist' do
    @group.template_categories.each do |category|
      @category = category
      step 'the template category contains articles'
    end
  end

  step 'the article is already used in many requests' do
    3.times do
      FactoryGirl.create :procurement_request,
                         template: @template
    end
    expect(@template.requests).to be_exists
  end

  step 'the article of the category is marked red' do
    within '.panel-collapse.in' do
      find ".bg-danger input[name*='[article_name]'][value='#{@template.article_name}']"
    end
  end

  step 'the articles inside a category are sorted 0-10 and a-z' do
    all('.panel-default').each do |panel|
      within panel do
        find('.panel-heading').click
        within '.panel-collapse.in' do
          texts = all("tbody tr input[name*='[article_name]']").map &:value
          texts.delete("")
          expect(texts).to eq texts.sort
        end
      end
    end
  end

  step 'the categories are sorted 0-10 and a-z' do
    texts = all('.panel-heading input').map &:value
    texts.delete("")
    expect(texts).to eq texts.sort
  end

  step 'the category article is deleted from the database' do
    expect { @template.reload }.to raise_error ActiveRecord::RecordNotFound
  end

  step 'the category is saved to the database' do
    category = Procurement::TemplateCategory.find_by_name(@name)
    expect(category).to be
    expect(category.name).to eq @name
  end

  step 'the data entered is saved to the database' do
    expect(@category.reload.templates.find_by(mapped_data)).to be
  end

  step 'the data modified is saved to the database' do
    @template.reload
    mapped_data.each_pair do |k,v|
      expect(@template.send k).to eq v
    end
  end

  step 'the deleted data is deleted from the database' do
    @template.reload

    expect(@template.article_name).not_to be_empty

    expect(@template.article_number).to be_nil
    expect(@template.price).to be_zero
    expect(@template.supplier).to be_nil
  end

  step 'the deleted template category is deleted from the database' do
    expect { @category.reload }.to raise_error ActiveRecord::RecordNotFound
  end

  step 'the following fields are filled' do |table|
    within '.panel-collapse.in' do
      el = if @template
             find :xpath, "//input[@value='#{@template.article_name}']/ancestor::tr"
           else
             all('tbody tr').last
           end
      within el do
        @data = {}
        table.raw.flatten.each do |value|
          case value
            when 'Price'
              find("input[name*='[price]']").set @data[value] = 123
            else
              fill_in _(value), with: @data[value] = Faker::Lorem.sentence
          end
        end
      end
    end
  end

  step 'the following fields are modified' do |table|
    step 'the following fields are filled', table
  end

  step 'the requests are nullified' do
    expect(@template.requests).to be_empty
  end

  step 'the template category contains articles' do
    3.times do
      @category.templates << FactoryGirl.create(:procurement_template)
    end
  end

  step 'the template category has one article' do
    @template = FactoryGirl.create(:procurement_template)
    @category.templates << @template
    expect(@category.templates.count).to eq 1
  end

  step 'the template category is marked red' do
    find ".panel-danger .panel-heading input[value='#{@category.name}']"
  end

  step 'there is an empty category line for creating a new category' do
    @el = all('.panel-default').last
    within @el do
      expect(find("input[name*='[name]']").value).to be_empty
    end
  end

  private

  def mapped_data
    h = {}
    h[:article_name] = @data['Article'] if @data['Article']
    if @data['Article nr. / Producer nr.']
      h[:article_number] = @data['Article nr. / Producer nr.']
    end
    h[:price_cents] = @data['Price'] * 100 if @data['Price']
    h[:supplier_name] = @data['Supplier'] if @data['Supplier']
    h
  end

end
