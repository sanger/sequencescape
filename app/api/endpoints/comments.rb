# frozen_string_literal: true
# Controls API V1 {::Core::Endpoint::Base endpoints} for Comments
class Endpoints::Comments < ::Core::Endpoint::Base
  model {}

  instance { belongs_to(:user, json: 'user') }
end
