class ::Endpoints::Users < ::Core::Endpoint::Base
  model do
  end

  instance do
    action(:update, :to => :standard_update!)
  end
end
