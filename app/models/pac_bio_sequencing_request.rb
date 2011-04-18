class PacBioSequencingRequest < Request
  INSERT_SIZE = [
    200,
    250,
    500,
    1000,
    2000,
    4000,
    6000,
    8000,
    10000
  ]

  SEQUENCING_TYPE = ["Standard","Strobe","Circular"]
  has_metadata :as => Request  do
    attribute(:insert_size, :default => 250, :in => INSERT_SIZE, :integer => true, :required =>true)
    attribute(:sequencing_type, :required => true, :in => SEQUENCING_TYPE)
  end

  class RequestOptionsValidator < DelegateValidation::Validator
    delegate_attribute :insert_size, :to => :target, :type_cast => :to_i
    validates_numericality_of :insert_size, :integer_only => true, :greater_than => 0

    validates_inclusion_of :insert_size, :in => PacBioSequencingRequest::INSERT_SIZE

    delegate_attribute :sequencing_type, :to => :target
    validates_inclusion_of :sequencing_type, :in => PacBioSequencingRequest::SEQUENCING_TYPE
  end

  def self.delegate_validator
    PacBioSequencingRequest::RequestOptionsValidator
  end

end
