class Request::LibraryCreation < Request
  # Override the behaviour of Request so that we do not copy the aliquots from our source asset
  # to the target when we are passed.  This is actually done by the TransferRequest from plate
  # to plate as it goes through being processed.
  include Request::StandardBillingStrategy

  def on_started
    # Override the default behaviour to not do the transfer
  end
end
