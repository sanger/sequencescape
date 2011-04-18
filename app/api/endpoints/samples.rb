class ::Endpoints::Samples < ::Core::Endpoint::Base
  model do
    action(:create, :to => :standard_create!)
  end

  instance do
    has_many(
      :sample_tubes, :json => 'sample_tubes', :to => 'sample_tubes',
      :include => [ :library_tubes, :sample, :requests ]
    )

    action(:update, :to => :standard_update!)
  end
end
