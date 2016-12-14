module Accession
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