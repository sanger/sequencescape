class ::Endpoints::Plates < ::Core::Endpoint::Base
  model do

  end

  instance do
    has_many(:requests,        :json => 'requests', :to => 'requests')
    belongs_to(:plate_purpose, :json => 'plate_purpose')
  end
end
