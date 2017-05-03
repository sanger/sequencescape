module Accession
  # A null response will be returned if accessioning errors.
  class NullResponse
    def faliure?
      true
    end

    def success?
      false
    end

    def accessioned?
      false
    end
  end
end
