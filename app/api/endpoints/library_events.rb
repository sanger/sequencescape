class ::Endpoints::LibraryEvents < ::Core::Endpoint::Base
  model do
    action(:create, to: :standard_create!)
  end

  instance do
    belongs_to(:seed, json: 'seed')
    belongs_to(:user, json: 'user')
  end
end
