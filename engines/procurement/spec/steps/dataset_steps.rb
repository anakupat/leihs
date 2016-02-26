module DatasetSteps

  step 'the basic dataset is ready' do
    step 'a procurement admin exists'
    step 'the current budget period exist'
    step 'there exists a procurement group'
    step 'there exist 3 requesters'
  end

end

RSpec.configure { |c| c.include DatasetSteps }
