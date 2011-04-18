class LibraryCreationRequest < Request
  LIBRARY_TYPES = [
    "No PCR",
    "High complexity and double size selected",
    "Illumina cDNA protocol",
    "Agilent Pulldown",
    "Custom",
    "High complexity",
    "ChiP-seq",
    "NlaIII gene expression",
    "Standard",
    "Long range",
    "Small RNA",
    "Double size selected",
    "DpnII gene expression",
    "qPCR only"
  ]

  has_metadata :as => Request do
    attribute(:fragment_size_required_from, :required =>true, :integer => true)
    attribute(:fragment_size_required_to, :required =>true, :integer =>true)
    attribute(:library_type, :default => 'Standard', :in => LIBRARY_TYPES, :required =>true)
    # /!\ We don't check the read_length, because we don't know the restriction, that depends on the SequencingRequest
    attribute(:read_length, :integer => true) # meaning , so not required but some people want to set it
  end

  def request_options_for_creation
    Hash[[:fragment_size_required_from, :fragment_size_required_to, :library_type].map { |f| [ f, request_metadata[f] ] }]
  end

  class RequestOptionsValidator < DelegateValidation::Validator
    delegate_attribute :fragment_size_required_from, :fragment_size_required_to, :to => :target, :type_cast => :to_i
    validates_numericality_of :fragment_size_required_from, :integer_only => true, :greater_than => 0
    validates_numericality_of :fragment_size_required_to,   :integer_only => true, :greater_than => 0

    delegate_attribute :library_type, :to => :target, :default => 'Standard'
    validates_inclusion_of :library_type, :in => LibraryCreationRequest::LIBRARY_TYPES
  end

  def self.delegate_validator
    LibraryCreationRequest::RequestOptionsValidator
  end
end
