class ::Endpoints::QcFiles < ::Core::Endpoint::Base
  model do
    #action(:create, :to => :standard_create!)
  end

  instance do
    # belongs_to :plate, :json => 'plate'
    has_file(:content_type=> 'sequencescape/qc_file')
  end

end
