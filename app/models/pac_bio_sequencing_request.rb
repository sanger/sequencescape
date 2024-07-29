# frozen_string_literal: true
class PacBioSequencingRequest < CustomerRequest
  self.sequencing = true

  delegate :pac_bio_library_tube_metadata, to: :source_tube, allow_nil: true
  delegate :movie_length, to: :pac_bio_library_tube_metadata, allow_nil: true
  delegate :insert_size, :sequencing_type, to: :request_metadata

  has_metadata as: Request do
    custom_attribute(:insert_size, validator: true, required: true, integer: true, selection: true)
    custom_attribute(:sequencing_type, validator: true, required: true, selection: true)
  end
  include Request::CustomerResponsibility

  class RequestOptionsValidator < DelegateValidation::Validator
    delegate_attribute :insert_size, to: :target, type_cast: :to_i
    validates :insert_size, numericality: { integer_only: true, greater_than: 0 }
    delegate_attribute :sequencing_type, to: :target
  end

  def self.delegate_validator
    PacBioSequencingRequest::RequestOptionsValidator
  end

  def on_started
  end

  def source_tube
    asset&.labware
  end
end
