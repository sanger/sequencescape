class ::Endpoints::Users < ::Core::Endpoint::Base
  model do

  end

  instance do
    # We don't need them right now
    #belongs_to(:workflow, :json => "workflow")
    #has_many(:batches, :include => [], :json => "batches", :to => "batches")
    #has_many(:comments, :include => [], :json => "comments", :to => "comments")
    #has_many(:events, :include => [], :json => "events", :to => "events")
    #has_many(:items, :include => [], :json => "items", :to => "items")
    #has_many(:lab_events, :include => [], :json => "lab_events", :to => "lab_events")
    #has_many(:requests, :include => [], :json => "requests", :to => "requests")
    
    # Doesn't exist anymore
    #has_many(:settings, :include => [], :json => "settings", :to => "settings")

  end
end
