class Endpoints::Projects < Core::Endpoint::Base # rubocop:todo Style/Documentation
  model do
  end

  instance do
    has_many(:submissions, json: 'submissions', to: 'submissions')
  end
end
