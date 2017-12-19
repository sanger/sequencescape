# frozen_string_literal: true

require_dependency 'pac_bio_sample_prep_request'

# Used for the transfer into the initial plate in the Sequencescape based PacBio pipeline
class TransferRequest::PacBioInitial < TransferRequest
  include TransferRequest::Initial::Behaviour
end
