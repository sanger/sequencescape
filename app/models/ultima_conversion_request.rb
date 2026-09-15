# frozen_string_literal: true

# Used for Illumina to Ultima library conversion.
class UltimaConversionRequest < CustomerRequest
  has_metadata as: Request do
    belongs_to :ultima_application

    association(:ultima_application, :name, required: true)
  end

  delegate :ultima_application, to: :request_metadata
end
