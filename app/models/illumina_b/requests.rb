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

    fragment_size_details(:no_default, :no_default)
  end

  class InputToCovaris < TransferRequest
    include TransferRequest::InitialTransfer
  end

  class CovarisToSheared < IlluminaHtp::Requests::CovarisToSheared
  end

  class PrePcrToPcr < IlluminaHtp::Requests::PrePcrToPcr
  end

  class PcrToPcrXp < IlluminaHtp::Requests::PcrToPcrXp
  end

  class PcrXpToStock < IlluminaHtp::Requests::PcrXpToStock
  end
end
