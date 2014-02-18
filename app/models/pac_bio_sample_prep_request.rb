class PacBioSamplePrepRequest < Request

  has_metadata :as => Request do
    attribute(:insert_size)
    attribute(:sequencing_type)
  end
  include Request::CustomerResponsibility

  class RequestOptionsValidator < DelegateValidation::Validator
  end

  def self.delegate_validator
    PacBioSamplePrepRequest::RequestOptionsValidator
  end

  private

  def on_started
    target_asset.generate_name(asset.display_name.gsub(':','-'))
  end

  def on_passed
    final_transfer.pass!
  end

  def on_failed
    final_transfer.fail!
  end

  def final_transfer
    target_asset.requests_as_target.where_is_a?(TransferRequest).last
  end

  class Initial < TransferRequest
    include TransferRequest::InitialTransfer
    def outer_request
      asset.requests.detect{|r| r.is_a?(PacBioSamplePrepRequest)}
    end
  end

end
