class PacBioSequencingRequest < Request

  SEQUENCING_TYPE = ["Standard","MagBead","Strobe","Circular"]
  has_metadata :as => Request  do
    attribute(:insert_size,      :validator => true, :required => true, :integer => true, :selection =>true  )
    attribute(:sequencing_type,  :validator => true, :required => true, :selection =>true                    )
  end

  include Request::CustomerResponsibility

  class RequestOptionsValidator < DelegateValidation::Validator
    delegate_attribute :insert_size, :to => :target, :type_cast => :to_i
    validates_numericality_of :insert_size, :integer_only => true, :greater_than => 0

    # validates_inclusion_of :insert_size, :in => PacBioSequencingRequest::INSERT_SIZE

    delegate_attribute :sequencing_type, :to => :target
  end

  def self.delegate_validator
    PacBioSequencingRequest::RequestOptionsValidator
  end

end
