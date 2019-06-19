# Controls API V1 {::Core::Endpoint::Base endpoints} for TagLayouts
class ::Endpoints::TagLayouts < ::Core::Endpoint::Base
  model do
    action(:create, to: :standard_create!)
  end

  instance do
    belongs_to(:plate, json: 'plate')
  end
end
