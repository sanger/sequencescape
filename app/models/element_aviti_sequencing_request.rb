# frozen_string_literal: true

class ElementAvitiSequencingRequest < SequencingRequest

  has_metadata as: Request do
    custom_attribute(:fragment_size_required_from, integer: true, minimum: 1)
    custom_attribute(:fragment_size_required_to, integer: true, minimum: 1)

    custom_attribute(:read_length, integer: true, validator: true, required: true, selection: true)
    custom_attribute(:requested_flowcell_type, required: false, validator: true, selection: true, on: :create)
    custom_attribute(:percent_element_phix_needed, integer: true, required: true, selection: true)
    custom_attribute(:low_diversity, required: true, selection: true)
  end
end
