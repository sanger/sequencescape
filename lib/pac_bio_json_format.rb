module ActiveResource::Formats::PacBioJsonFormat
  class << self
    def decode(json)
      ActiveSupport::JSON.decode(json)["Rows"]
    end
    def extension
      "json"
    end
    def encode(hash, options = nil)
      ActiveSupport::JSON.encode(hash, options)
    end
    def mime_type
      "application/json"
    end
  end
end