module IlluminaB::Requests

  class StdLibraryRequest < Request::LibraryCreation
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
