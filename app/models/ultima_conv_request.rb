# frozen_string_literal: true

# Used for Illumina to Ultima library conversion.
class UltimaConvRequest < CustomerRequest
  has_metadata as: Request do
    custom_attribute(:application_type)
  end
end
