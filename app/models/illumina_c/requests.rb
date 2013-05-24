module IlluminaC::Requests

  class LibraryRequest < Request::LibraryCreation

  end

  class PcrLibraryRequest < LibraryRequest
    LIBRARY_TYPES = [
      'Standard'
    ]

    DEFAULT_LIBRARY_TYPE = 'Standard'

    fragment_size_details(:no_default, :no_default)
  end

  class NoPcrLibraryRequest < LibraryRequest
    LIBRARY_TYPES = [
      'Standard'
    ]

    DEFAULT_LIBRARY_TYPE = 'Standard'

    fragment_size_details(:no_default, :no_default)
  end

  class InitialTransfer < TransferRequest
    include TransferRequest::InitialTransfer
  end

end
