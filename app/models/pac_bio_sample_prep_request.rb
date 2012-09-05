class PacBioSamplePrepRequest < Request
  has_metadata :as => Request do
    attribute(:insert_size)
    attribute(:sequencing_type)
  end

  class RequestOptionsValidator < DelegateValidation::Validator
  end

  def self.delegate_validator
    PacBioSamplePrepRequest::RequestOptionsValidator
  end

end
