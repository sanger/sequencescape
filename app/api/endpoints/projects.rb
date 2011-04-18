class Endpoints::Projects < Core::Endpoint::Base
  model do

  end

  instance do
    has_many(:submissions, :json => 'submissions', :to => 'submissions')
  end
end
