# frozen_string_literal: true

class ElementAvitiSequencingRequest < SequencingRequest
  has_metadata as: Request do
    custom_attribute(:fragment_size_required_from, integer: true, minimum: 1)
    custom_attribute(:fragment_size_required_to, integer: true, minimum: 1)
    custom_attribute(:read_length, integer: true, validator: true, required: true, selection: true)
    custom_attribute(:requested_flowcell_type, required: false, validator: true, selection: true, on: :create)

    custom_attribute(:percent_phix_requested, integer: true, required: true, minimum: 0, maximum: 100)
    custom_attribute(
      :low_diversity,
      boolean_select: true,
      required: true,
      default: 0,
      select_options: {
        Yes: 1,
        No: 0
      }
    )
  end

  class ElementAvitiRequestOptionsValidator < SequencingRequest::RequestOptionsValidator
    validates :percent_phix_requested,
              numericality: {
                integer_only: true,
                greater_than_or_equal_to: 0,
                less_than_or_equal_to: 100,
                allow_nil: false
              }
  end

  def self.deletage_validator
    ElementAvitiSequencingRequest::ElementAvitiRequestOptionsValidator
  end
end
