# frozen_string_literal: true

class ElementAvitiSequencingRequest < SequencingRequest
  YES_OR_NO = %w[Yes No].freeze

  # XXX: Calling has_metadata again overrides the parent call. Parent attributes
  # are added here for now.
  has_metadata as: Request do
    custom_attribute(:fragment_size_required_from, integer: true, minimum: 1)
    custom_attribute(:fragment_size_required_to, integer: true, minimum: 1)
    custom_attribute(:read_length, integer: true, validator: true, required: true, selection: true)
    custom_attribute(:requested_flowcell_type, required: false, validator: true, selection: true, on: :create)

    custom_attribute(:percent_phix_requested, integer: true, required: true, minimum: 0, maximum: 100)
    custom_attribute(:low_diversity, required: true, in: YES_OR_NO)
  end
end
