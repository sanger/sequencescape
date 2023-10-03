# frozen_string_literal: true
class PacBioSamplePrepRequest < CustomerRequest
  delegate :pac_bio_library_tube_metadata, to: :target_tube, allow_nil: true
  delegate :movie_length, to: :pac_bio_library_tube_metadata, allow_nil: true

  has_metadata as: Request do
    custom_attribute(:insert_size)
    custom_attribute(:sequencing_type)
  end
  include Request::CustomerResponsibility

  class RequestOptionsValidator < DelegateValidation::Validator
  end

  def self.delegate_validator
    PacBioSamplePrepRequest::RequestOptionsValidator
  end

  private

  def target_tube
    target_asset&.labware
  end

  def on_started
    target_asset.labware.update!(name: asset.display_name.tr(':', '-'))
  end

  def on_passed
    final_transfers.each(&:pass!)
  end

  def on_failed
    final_transfers.each(&:fail!)
  end

  def final_transfers
    target_asset.transfer_requests_as_target
  end
end
