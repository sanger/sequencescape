class ::Endpoints::Plates < ::Core::Endpoint::Base
  model do

  end

  instance do
    has_many(:requests,                  :json => 'requests', :to => 'requests')
    belongs_to(:plate_purpose,           :json => 'plate_purpose')
    belongs_to(:transfer_as_destination, :json => 'creation_transfer')
  end
end
