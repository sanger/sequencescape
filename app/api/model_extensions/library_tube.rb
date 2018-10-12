module ModelExtensions::LibraryTube
  def self.included(base)
    base.class_eval do
      scope :include_source_request, -> { includes(source_request: [:uuid_object, :request_metadata]) }
    end
  end
end
