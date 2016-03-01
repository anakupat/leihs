
placeholder :string_with_spaces do
  match /.*/ do |s|
    s
  end
end

placeholder :boolean do
  match 'is not' do
    false
  end

  match 'is' do
    true
  end
end
