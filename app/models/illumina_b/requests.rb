module IlluminaB::Requests

  class StdLibraryRequest < Request::LibraryCreation
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

    def request_options_for_creation
      Hash[[:fragment_size_required_from, :fragment_size_required_to, :library_type].map { |f| [ f, request_metadata[f] ] }]
    end
  end

end
