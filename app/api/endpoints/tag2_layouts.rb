# Controls API V1 {::Core::Endpoint::Base endpoints} for Tag2Layouts
class ::Endpoints::Tag2Layouts < ::Core::Endpoint::Base
  model do
    action(:create, to: :standard_create!)
  end

  instance do
    belongs_to(:plate,  json: 'plate')
    belongs_to(:source, json: 'source')
  end
end
