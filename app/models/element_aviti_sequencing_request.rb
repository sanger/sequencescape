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
      default: '0',
      select_options: {
        Yes: 1,
        No: 0
      }
    )
  end

  # TODO: Check if we need to include CustomerResponsibility again here after has_metadata.

  class ElementAvitiRequestOptionsValidator < SequencingRequest::RequestOptionsValidator
    delegate :percent_phix_requested, to: :target
    delegate :requested_flowcell_type, to: :target
    delegate :read_length, to: :target

    validates :percent_phix_requested,
              numericality: {
                integer_only: true,
                greater_than_or_equal_to: 0,
                less_than_or_equal_to: 100,
                allow_nil: false
              }

    validate :requested_flowcell_type_read_length_compatibility

    def requested_flowcell_type_read_length_compatibility
      return unless requested_flowcell_type.name == 'LO' && read_length.to_i != 150
      errors.add(
        :requested_flowcell_type,
        'For the LO (Low Output) flowcell kit the user can select a Read Length of 150'
      )
    end
  end

  def self.delegate_validator
    ElementAvitiSequencingRequest::ElementAvitiRequestOptionsValidator
  end
end
