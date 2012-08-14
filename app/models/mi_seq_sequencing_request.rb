class MiSeqSequencingRequest < SequencingRequest
  READ_LENGTHS = [25, 50, 130, 150, 250]
  has_metadata :as => Request  do
    #redundant with library creation , but THEY are using it .
    attribute(:fragment_size_required_from, :required =>true, :integer => true)
    attribute(:fragment_size_required_to, :required =>true, :integer =>true)

    attribute(:read_length, :integer => true, :required => true, :in => READ_LENGTHS)
  end

  class RequestOptionsValidator < DelegateValidation::Validator
    delegate_attribute :read_length, :to => :target, :type_cast => :to_i
    validates_numericality_of :read_length, :integer_only => true, :greater_than => 0
    validates_inclusion_of :read_length, :in => MiSeqSequencingRequest::READ_LENGTHS
  end

  def self.delegate_validator
    MiSeqSequencingRequest::RequestOptionsValidator
  end
end
