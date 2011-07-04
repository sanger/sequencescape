class PulldownLibraryCreationRequest < Request
  LIBRARY_TYPES = [
    'Standard',
    'Agilent Pulldown'
  ]

  DEFAULT_LIBRARY_TYPE = 'Standard'

  # NOTE: Do not alter the order here:
  #
  # 1. has_metadata :as => Request
  # 2. include Request::LibraryManufacture
  #
  # These are dependent upon each other
  has_metadata :as => Request do
    include BaitLibrary::Associations
    association(:bait_library, :name)
  end

  include Request::LibraryManufacture

  # Override the behaviour of Request so that we do not copy the aliquots from our source asset
  # to the target when we are passed.  This is actually done by the TransferRequest from plate
  # to plate as it goes through being processed.
  def on_passed
    # Override the default behaviour to not do the transfer
  end
end
