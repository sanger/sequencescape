
class ::Endpoints::TagLayouts < ::Core::Endpoint::Base
  model do
    action(:create, to: :standard_create!)
  end

  instance do
    belongs_to(:plate, json: 'plate')
  end
end
