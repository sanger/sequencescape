class ::Endpoints::Users < ::Core::Endpoint::Base
  model do
  end

  instance do
    action(:update, :to => :standard_update!)
    action_requires_authorisation(:update)

  end
end
