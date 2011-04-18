module ModelExtensions::SampleTube
  def self.included(base)
    base.class_eval do
      has_many :library_tubes, :through => :links_as_parent, :source => :descendant

      named_scope :include_sample, :include => { :sample => :uuid_object }
      named_scope :include_scanned_into_lab_event, :include => :scanned_into_lab_event
    end
  end
end
