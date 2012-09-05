class LibraryCreationRequest < Request
  LIBRARY_TYPES = [
    "No PCR",
    "High complexity and double size selected",
    "Illumina cDNA protocol",
    "Agilent Pulldown",
    "Custom",
    "High complexity",
    "ChiP-seq",
    "NlaIII gene expression",
    "Standard",
    "Long range",
    "Small RNA",
    "Double size selected",
    "DpnII gene expression",
    "TraDIS",
    "qPCR only",
    "Pre-quality controlled",
    "DSN_RNAseq"
  ]

  DEFAULT_LIBRARY_TYPE = 'Standard'

  # NOTE: Do not alter the order here:
  #
  # 1. has_metadata :as => Request
  # 2. include Request::LibraryManufacture
  # 3. class RequestOptionsValidator
  #
  # These are dependent upon each other
  has_metadata :as => Request do
    # /!\ We don't check the read_length, because we don't know the restriction, that depends on the SequencingRequest
    attribute(:read_length, :integer => true) # meaning , so not required but some people want to set it
  end

  include Request::LibraryManufacture

  # When a library creation request passes it does the default behaviour of a request but also adds the
  # insert size to the aliquots in the target asset and sets the library.  There's a minor complication in that
  # an MX library is also a type of library that might have libraries coming into it, therefore we only update the
  # information that is missing.
  def on_started
    super
    target_asset.aliquots.each do |aliquot|
      aliquot.library      ||= target_asset
      aliquot.library_type ||= library_type
      aliquot.insert_size  ||= insert_size
      aliquot.save!
    end
  end

  def request_options_for_creation
    Hash[[:fragment_size_required_from, :fragment_size_required_to, :library_type].map { |f| [ f, request_metadata[f] ] }]
  end
end
