# frozen_string_literal: true
# A class for requests generated by auto-submission for the Duplex-Seq and Targeted Nanoseq pipelines
class DilutionAndCleanupRequest < CustomerRequest
  has_metadata as: Request do
    include Pulldown::Requests::BaitLibraryRequest::BaitMetadata

    custom_attribute(:pcr_cycles, integer: true, minimum: 0, required: false, validator: true)

    # These fields are inside the json field stored_metadata
    custom_attribute(:input_amount_desired, positive_float: true, required: false, validator: true)
    custom_attribute(:diluent_volume, positive_float: true, required: false, validator: true)
    custom_attribute(:submit_for_sequencing, boolean: true, required: false, validator: true)
    custom_attribute(:sub_pool, integer: true, minimum: 0, required: false, validator: true)
    custom_attribute(:coverage, integer: true, minimum: 0, required: false, validator: true)
  end
end
