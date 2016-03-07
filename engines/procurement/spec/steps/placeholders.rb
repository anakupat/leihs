
placeholder :string_with_spaces do
  match /.*/ do |s|
    s
  end
end

placeholder :boolean do
  match /(is not|do not see)/ do
    false
  end

  match /(is|see)/ do
    true
  end
end
