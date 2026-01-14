# frozen_string_literal: true
class NovaSeq6000PESequencingRequest < SequencingRequest
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
  end

  # Delegate to request_metadata so the attributes are visible to the validator in the RSpec tests.
  # This delegation has no real effect outside of the tests.
  delegate :requested_flowcell_type, :read_length, to: :request_metadata

  class NovaSeq6000PERequestOptionsValidator < DelegateValidation::Validator
    delegate :requested_flowcell_type, :read_length, :request_types, to: :target

    validate :validate_read_length_by_selected_flowcell_type

    def validate_read_length_by_selected_flowcell_type
      return unless requested_flowcell_type != 'SP' && read_length.to_i == 250

      errors.add(:read_length,
                 'The user can only select a Read Length of 250 with the SP flowcell type for NovaSeq 6000 PE requests')
    end
  end

  def self.delegate_validator
    NovaSeq6000PESequencingRequest::NovaSeq6000PERequestOptionsValidator
  end
end
