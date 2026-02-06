# frozen_string_literal: true
class NovaSeq6000PESequencingRequest < SequencingRequest
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
