# frozen_string_literal: true
class Endpoints::Projects < Core::Endpoint::Base # rubocop:todo Style/Documentation
  model {}

  instance { has_many(:submissions, json: 'submissions', to: 'submissions') }
end
