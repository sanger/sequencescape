# frozen_string_literal: true
class HiSeqSequencingRequest < SequencingRequest
  # Delegate to request_metadata so the attributes are visible to the validator in the RSpec tests.
  # This delegation has no real effect outside of the tests.
  delegate :requested_flowcell_type, :read_length, to: :request_metadata

  # Read lengths allowed for every flowcell type except '1.5B'.
  # Covers '10B', '25B', '5B', and any future flowcell type added to this request type.
  STANDARD_READ_LENGTHS = [50, 100, 150].freeze

  # '1.5B' additionally allows 300, on top of the standard read lengths.
  FLOWCELL_1_5B = '1.5B'
  READ_LENGTH_1_5B_ONLY = 300
  READ_LENGTHS_FOR_1_5B = (STANDARD_READ_LENGTHS + [READ_LENGTH_1_5B_ONLY]).freeze

  class NovaSeqXPERequestOptionsValidator < DelegateValidation::Validator
    delegate :requested_flowcell_type, :read_length, :request_types, to: :target

    validate :validate_read_length_by_selected_flowcell_type

    def validate_read_length_by_selected_flowcell_type
      # Presence is already enforced by the custom_attribute :required option;
      # skip this cross-field check until both values are present.
      return if requested_flowcell_type.blank? || read_length.blank?

      if requested_flowcell_type == HiSeqSequencingRequest::FLOWCELL_1_5B
        validate_1_5b_read_length
      else
        validate_standard_read_length
      end
    end

    private

    def validate_1_5b_read_length
      return if HiSeqSequencingRequest::READ_LENGTHS_FOR_1_5B.include?(read_length.to_i)

      errors.add(
        :read_length,
        'can only be one of ' \
        "#{HiSeqSequencingRequest::READ_LENGTHS_FOR_1_5B.join(', ')} when the flowcell type is " \
        "#{HiSeqSequencingRequest::FLOWCELL_1_5B}"
      )
    end

    def validate_standard_read_length
      return if HiSeqSequencingRequest::STANDARD_READ_LENGTHS.include?(read_length.to_i)

      errors.add(
        :read_length,
        "can only be one of #{HiSeqSequencingRequest::STANDARD_READ_LENGTHS.join(', ')} " \
        "when the flowcell type is not #{HiSeqSequencingRequest::FLOWCELL_1_5B}"
      )
    end
  end

  def self.delegate_validator
    HiSeqSequencingRequest::NovaSeqXPERequestOptionsValidator
  end
end
