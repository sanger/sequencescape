module EventfulRecord
  def has_many_events(&block)
    has_many(:events, :as => :eventful, :dependent => :destroy, :order => 'created_at', &block)
  end
  
  def has_many_lab_events(&block)
    has_many(:lab_events, :as => :eventful, :dependent => :destroy, :order => 'created_at', &block)
  end

  def has_one_event_with_family(event_family, &block)
    has_one(:"#{event_family}_event", :class_name => 'Event', :as => :eventful, :conditions => { :family => event_family }, :order => 'id DESC', &block)
  end
end
