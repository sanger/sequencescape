module ModelExtensions::LibraryTube
  def self.included(base)
    base.class_eval do
      named_scope :include_source_request, :include => { :source_request => [ :uuid_object, :request_metadata ] }
    end
  end
end
