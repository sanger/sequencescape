class PulldownMultiplexedLibraryCreationRequest < CustomerRequest
  # override default behavior to not copy the aliquots
  def on_started
  end
end
