class ::Endpoints::ReferenceGenomes < ::Core::Endpoint::Base
  model do
    action(:create, :to => :standard_create!)
  end

  instance do
    action(:update, :to => :standard_update!)
  end
end
