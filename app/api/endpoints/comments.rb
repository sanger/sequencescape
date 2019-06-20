# Controls API V1 {::Core::Endpoint::Base endpoints} for Comments
class ::Endpoints::Comments < ::Core::Endpoint::Base
  model do
  end

  instance do
    belongs_to(:user, json: 'user')
  end
end
