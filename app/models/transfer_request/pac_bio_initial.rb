require_dependency 'pac_bio_sample_prep_request'

class TransferRequest::PacBioInitial < TransferRequest
  include TransferRequest::Initial::Behaviour
  def outer_request
    asset.requests.detect { |r| r.is_a?(PacBioSamplePrepRequest) }
  end
end
