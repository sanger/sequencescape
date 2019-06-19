# Controls API V1 {::Core::Endpoint::Base endpoints} for ExtractionAttributes
class ::Endpoints::ExtractionAttributes < ::Core::Endpoint::Base
  model do
    action(:create, to: :standard_create!)
  end

  instance do
    belongs_to(:target, json: 'target')
  end
end
