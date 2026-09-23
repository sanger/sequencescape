# frozen_string_literal: true

class HiSeqSequencingRequest < SequencingRequest
  # Delegate to request_metadata so the attributes are visible to the validator in the RSpec tests.
  # This delegation has no real effect outside of the tests.
  delegate :fragment_size_required_from, :fragment_size_required_to, :requested_flowcell_type, :read_length,
           to: :request_metadata

  FLOWCELL_1_5B = '1.5B'
  READ_LENGTH_1_5B_ONLY = 300
  # Used in the error message only; keep in sync with ReadLengthRequestedNovaseqX
  # in config/default_records/request_type_validators/default_records.yml.
  STANDARD_READ_LENGTHS = [50, 100, 150].freeze

  class NovaSeqXPERequestOptionsValidator < SequencingRequest::RequestOptionsValidator
    delegate :requested_flowcell_type, :read_length, to: :target

    validate :validate_300_read_length

    # The full set of valid read lengths is enforced by the request type's own
    # RequestType::Validator (loaded from config/default_records/request_type_validators).
    # This cross-field check only restricts 300 to the 1.5B flowcell type.
    def validate_300_read_length
      return if read_length.blank?
      return unless read_length.to_i == READ_LENGTH_1_5B_ONLY
      return if requested_flowcell_type == FLOWCELL_1_5B

      errors.add(:read_length, restricted_read_length_message)
    end

    private

    def restricted_read_length_message
      base = "#{READ_LENGTH_1_5B_ONLY} is only available for the #{FLOWCELL_1_5B} flowcell type"
      return "#{base}, but no flowcell type was selected." if requested_flowcell_type.blank?

      "#{base}. Available read lengths for the " \
        "#{requested_flowcell_type} flowcell type are #{STANDARD_READ_LENGTHS.join(', ')}."
    end
  end

  def self.delegate_validator
    NovaSeqXPERequestOptionsValidator
  end
end
