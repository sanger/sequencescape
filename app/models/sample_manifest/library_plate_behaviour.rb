# frozen_string_literal: true

module SampleManifest::LibraryPlateBehaviour
  # Generates plates containing libraries. Contrary to SampleManifest::LibraryPlateBehaviour::Core
  # it sets library_id on aliquots in wells and doesn't generate stock assets.
  class Core < SampleManifest::PlateBehaviour::Base
    include SampleManifest::CoreBehaviour::LibraryAssets
  end
end
