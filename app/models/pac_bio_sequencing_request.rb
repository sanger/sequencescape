class PacBioSequencingRequest < CustomerRequest
  include Request::CustomerResponsibility

  self.sequencing = true

  has_metadata as: Request do
    custom_attribute(:insert_size,      validator: true, required: true, integer: true, selection: true)
    custom_attribute(:sequencing_type,  validator: true, required: true, selection: true)
  end

  class RequestOptionsValidator < DelegateValidation::Validator
    delegate_attribute :insert_size, to: :target, type_cast: :to_i
    validates_numericality_of :insert_size, integer_only: true, greater_than: 0
    delegate_attribute :sequencing_type, to: :target
  end

  def self.delegate_validator
    PacBioSequencingRequest::RequestOptionsValidator
  end

  def on_started
  end

  # Returns a list of attributes that must match for any given pool
  def shared_attributes
    "MovieLength:#{asset.pac_bio_library_tube_metadata.movie_length};InsertSize:#{request_metadata.insert_size};SequencingType:#{request_metadata.sequencing_type};"
  end
end
