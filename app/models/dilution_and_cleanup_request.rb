# frozen_string_literal: true
# A class for requests generated by auto-submission for the Duplex-Seq and Targeted Nanoseq pipelines
class DilutionAndCleanupRequest < CustomerRequest
  has_metadata as: Request do
    custom_attribute(:pcr_cycles, integer: true, minimum: 0, validator: true)
    custom_attribute(:bait_library_id, integer: true, minimum: 0, validator: true)
    # These 4 fields are inside the json field stored_metadata
    custom_attribute(:submit_for_sequencing, required: true)
    custom_attribute(:sub_pool, integer: true, required: true)
    custom_attribute(:coverage, integer: true, required: true)
    custom_attribute(:diluent_volume, positive_float: true, required: true)
  end
end
