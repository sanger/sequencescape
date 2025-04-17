# frozen_string_literal: true

class ElementAvitiSequencingRequest < SequencingRequest
  YES = 'Yes'
  NO = 'No'
  YES_OR_NO = [NO, YES].freeze

  has_metadata as: Request do
    # Defining the sequencing request metadata here again, as 'has_metadata'
    # does not automatically append these custom attributes to the request.
    #
    # The has_metadata call dynamically defines an inner Metadata class and
    # takes the attributes from the block and adds them to the Metadata class.
    # There is an assumption that the inner Metadata class is available in a
    # sequencing request class defintion. Calling has_metadata again does not
    # inherit the attributes given in the block supplied in the superclass.
    # They need to be supplied again for this class for a proper inner Metadata
    # class definition. In a future refactoring these attributes can be moved a
    # class attribute and subclasses can merge its own attibutes to that. A
    # common method can set up the inner Metadata class in the subclasses.
    custom_attribute(:fragment_size_required_from, integer: true, minimum: 1)
    custom_attribute(:fragment_size_required_to, integer: true, minimum: 1)
    custom_attribute(:read_length, integer: true, validator: true, required: true, selection: true)
    custom_attribute(:requested_flowcell_type, required: true, validator: true, selection: true)

    custom_attribute(:percent_phix_requested, integer: true, required: true, minimum: 0)
    custom_attribute(:low_diversity, default: NO, in: YES_OR_NO, required: true)
    enum :low_diversity, { Yes: true, No: false }
  end

  # Delegate to request_metadata so the attributes are visible to the validator in the RSpec tests.
  # This delegation has no real effect outside of the tests.
  delegate :percent_phix_requested, :requested_flowcell_type, :read_length, to: :request_metadata

  class ElementAvitiRequestOptionsValidator < DelegateValidation::Validator
    delegate :percent_phix_requested, :requested_flowcell_type, :read_length, to: :target

    # Adding another validation for percent_phix_requested here as 'maximum' is not supported
    # in the attribute-level
    validates :percent_phix_requested, numericality: { integer_only: true, less_than_or_equal_to: 100 }

    validate :validate_read_length_by_selected_flowcell_type

    def validate_read_length_by_selected_flowcell_type
      return unless requested_flowcell_type == 'LO' && read_length.to_i != 150
      errors.add(:read_length, 'For the LO (Low Output) flowcell kit the user can select a Read Length of 150')
    end
  end

  def self.delegate_validator
    ElementAvitiSequencingRequest::ElementAvitiRequestOptionsValidator
  end
end
