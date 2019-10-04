# Included in {MultiplexedLibraryTube} to provide scopes used by the V1 API
# @note This could easily be in-lined in MultiplexedLibraryTube itself
module ModelExtensions::MultiplexedLibraryTube
  def self.included(base)
    base.class_eval do
      scope :include_source_request, -> { includes(source_request: %i[uuid_object request_metadata]) }
    end
  end
end
