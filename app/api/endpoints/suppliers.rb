# Controls API V1 {::Core::Endpoint::Base endpoints} for Suppliers
class ::Endpoints::Suppliers < ::Core::Endpoint::Base
  model do
  end

  instance do
    has_many(:sample_manifests, include: [], json: 'sample_manifests', to: 'sample_manifests')
  end
end
