# frozen_string_literal: true
# Controls API V1 {::Core::Endpoint::Base endpoints} for WorkCompletions
class Endpoints::WorkCompletions < Core::Endpoint::Base
  model { action(:create, to: :standard_create!) }

  instance do
    belongs_to(:target, json: 'target')
    belongs_to(:user, json: 'user')
    has_many(:submissions, json: 'submissions', to: 'submissions')
  end
end
