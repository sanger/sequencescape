class PulldownLibraryCreationRequest < Request
  has_metadata :as => Request do
    attribute(:fragment_size_required_from, :required => true, :integer => true)
    attribute(:fragment_size_required_to,   :required => true, :integer => true)

    include BaitLibrary::Associations
    association(:bait_library, :name)
  end

  # Override the behaviour of Request so that we do not copy the aliquots from our source asset
  # to the target when we are passed.  This is actually done by the TransferRequest from plate
  # to plate as it goes through being processed.
  def on_passed
    # Override the default behaviour to not do the transfer
  end
end
