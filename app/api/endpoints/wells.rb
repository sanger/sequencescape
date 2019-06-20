# Controls API V1 {::Core::Endpoint::Base endpoints} for Wells
class ::Endpoints::Wells < ::Core::Endpoint::Base
  model do
  end

  instance do
    belongs_to :plate, json: 'plate'
  end
end
