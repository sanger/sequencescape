# frozen_string_literal: true

# A class for customer requests that need the extra metadata fields used for PBMC pooling calculations
class PbmcPoolingCustomerRequest < CustomerRequest
  has_metadata as: Request do
    custom_attribute(:number_of_samples_per_pool, integer: true, required: false, default: nil)
    custom_attribute(:cells_per_chip_well, integer: true, required: false, default: nil)
  end
end
