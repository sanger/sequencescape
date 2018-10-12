class PacBioSamplePrepRequest < CustomerRequest
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

  def on_started
    target_asset.generate_name(asset.display_name.tr(':', '-'))
    target_asset.save
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
