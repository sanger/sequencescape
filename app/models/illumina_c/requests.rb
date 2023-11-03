# frozen_string_literal: true
module IlluminaC::Requests
  class LibraryRequest < Request::LibraryCreation
    def role
      "#{request_metadata.library_type} #{super}"
    end

    # Pop the request type in the pool information
    def update_pool_information(pool_information)
      super
      pool_information[:request_type] = request_type.name
    end

    fragment_size_details(:no_default, :no_default)
  end

  # The following two classes are redundant and are due for removal:
  # Stage 1:
  # Refactor to allow use of IlluminaC::Requests::LibraryRequest [Done: This commit]
  # Step 2:
  # Write migration to update existing request types / requests to use IlluminaC::Requests::LibraryRequest
  # [Will be done soon]
  # Also update the configuration below to ensure the seeds behave correctly
  # Step 3:
  # Remove these classes
  # By splitting this process over three releases we avoid the need for downtime during migrations
  class PcrLibraryRequest < LibraryRequest
  end

  class NoPcrLibraryRequest < LibraryRequest
  end
end
