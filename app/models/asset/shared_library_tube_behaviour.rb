# frozen_string_literal: true

# Included in {LibraryTube} and {MultiplexedLibraryTube}
module Asset::SharedLibraryTubeBehaviour
  extend ActiveSupport::Concern

  included do
    include Asset::ApplyIdToNameOnCreate

    self.sequenceable = true
  end

  def library_source_plates
    purpose.try(:library_source_plates, self) || []
  end
end
