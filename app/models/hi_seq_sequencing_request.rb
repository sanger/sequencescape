class HiSeqSequencingRequest < SequencingRequest
  READ_LENGTHS = [50, 75, 100, 125]
  has_metadata :as => Request  do
    #redundant with library creation , but THEY are using it .
    attribute(:fragment_size_required_from, :required =>true, :integer => true)
    attribute(:fragment_size_required_to, :required =>true, :integer =>true)

    attribute(:read_length, :integer => true, :required => true, :in => READ_LENGTHS)
  end

  class RequestOptionsValidator < DelegateValidation::Validator
    delegate_attribute :read_length, :to => :target, :type_cast => :to_i
    validates_inclusion_of :read_length, :in => HiSeqSequencingRequest::READ_LENGTHS, :if => :read_length_needs_checking?
  end

  def self.delegate_validator
    HiSeqSequencingRequest::RequestOptionsValidator
  end
end
