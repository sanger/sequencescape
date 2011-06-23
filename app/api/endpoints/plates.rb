class ::Endpoints::Plates < ::Core::Endpoint::Base
  model do

  end

  instance do
    has_many(:requests,                  :json => 'requests', :to => 'requests')
    belongs_to(:plate_purpose,           :json => 'plate_purpose')

    has_many(:transfers_as_source,       :json => 'source_transfers', :to => 'source_transfers')
    belongs_to(:transfer_as_destination, :json => 'creation_transfer')
  end
end
