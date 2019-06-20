# Controls API V1 {::Core::Endpoint::Base endpoints} for StateChanges
class ::Endpoints::StateChanges < ::Core::Endpoint::Base
  model do
    action(:create, to: :standard_create!)
  end

  instance do
    belongs_to(:target, json: 'target')
    belongs_to(:user, json: 'user')
  end
end
