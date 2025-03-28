# frozen_string_literal: true

class ElementAvitiSequencingRequest < SequencingRequest
  has_metadata as: Request do
    # Re-declare inherited attributes as has_metadata does not automatically merge inherited attributes
    custom_attribute(:fragment_size_required_from, integer: true, minimum: 1)
    custom_attribute(:fragment_size_required_to, integer: true, minimum: 1)
    custom_attribute(:read_length, integer: true, validator: true, required: true, selection: true)
    custom_attribute(:requested_flowcell_type, required: false, validator: true, selection: true, on: :create)

    custom_attribute(:percent_phix_requested, integer: true, required: true, minimum: 0, maximum: 100)
    custom_attribute(:low_diversity, required: true, boolean: true, default: false)
  end
end
