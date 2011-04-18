module ModelExtensions::LibraryTube
  def self.included(base)
    base.class_eval do
      named_scope :include_source_request, :include => { :source_request => [ :uuid_object, :request_metadata ] }
      named_scope :include_sample, :include => { :sample => :uuid_object }
      named_scope :include_scanned_into_lab_event, :include => :scanned_into_lab_event
    end
  end
end
