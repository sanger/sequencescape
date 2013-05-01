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

  class SharedLibraryPrep < StdLibraryRequest
    def target_tube
      @target_tube ||= submission.next_requests(self).detect {|r| r.target_tube }.try(:target_tube)
    end

        # Ensure that the bait library information is also included in the pool information.
    def update_pool_information(pool_information)
      super
      pool_information[:target_tube_purpose] = target_tube.purpose.uuid if target_tube
    end

    def role
      order.role
    end
  end

  class LibraryCompletion < StdLibraryRequest

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
