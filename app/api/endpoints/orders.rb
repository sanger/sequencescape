# frozen_string_literal: true
class Endpoints::Orders < Core::Endpoint::Base # rubocop:todo Style/Documentation
  model {}

  instance do
    belongs_to(:project, json: 'project')
    belongs_to(:study, json: 'study')
    belongs_to(:user, json: 'user')

    action(:update, to: :standard_update!, if: :building?)
  end
end
