module Pulldown::Requests
  module BaitLibraryRequest
    def self.included(base)
      base.class_eval do
        const_set(:DEFAULT_LIBRARY_TYPE, 'Agilent Pulldown')
        const_set(:LIBRARY_TYPES, [ 'Agilent Pulldown' ])

        has_metadata :as => Request do
          include BaitLibrary::Associations
          association(:bait_library, :name)
        end
        include Request::LibraryManufacture
      end
    end
  end

  # Override the behaviour of Request so that we do not copy the aliquots from our source asset
  # to the target when we are passed.  This is actually done by the TransferRequest from plate
  # to plate as it goes through being processed.
  class LibraryCreation < Request
    def on_started
      # Override the default behaviour to not do the transfer
    end
  end

  class WgsLibraryRequest < LibraryCreation
    DEFAULT_LIBRARY_TYPE = 'Standard'
    LIBRARY_TYPES        = [ DEFAULT_LIBRARY_TYPE ]

    has_metadata :as => Request
    include Request::LibraryManufacture
  end

  class ScLibraryRequest < LibraryCreation
    include BaitLibraryRequest
  end

  class IscLibraryRequest < LibraryCreation
    include BaitLibraryRequest
  end
end
