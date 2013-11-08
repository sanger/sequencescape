class HiSeq2500SequencingRequest < HiSeqSequencingRequest
  READ_LENGTHS = [75, 100, 150]

  class RequestOptionsValidator < DelegateValidation::Validator
    delegate_attribute :read_length, :to => :target, :type_cast => :to_i
    validates_inclusion_of :read_length, :in => HiSeq2500SequencingRequest::READ_LENGTHS, :if => :read_length_needs_checking?
  end

  def self.delegate_validator
    HiSeq2500SequencingRequest::RequestOptionsValidator
  end
end
