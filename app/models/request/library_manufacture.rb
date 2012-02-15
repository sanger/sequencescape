# Any request involved in building a library should include this module that defines some of the
# most common behaviour, namely the library type and insert size information.
module Request::LibraryManufacture
  def self.included(base)
    base::Metadata.class_eval do
      attribute(:fragment_size_required_from, :required => true, :integer => true)
      attribute(:fragment_size_required_to,   :required => true, :integer => true)

      attribute(:library_type, { :in => base::LIBRARY_TYPES, :default => base::DEFAULT_LIBRARY_TYPE, :required => true })
    end

    base.class_eval do
      extend ClassMethods
    end
    base.const_set(:RequestOptionsValidator, Class.new(DelegateValidation::Validator) do
      delegate_attribute :fragment_size_required_from, :fragment_size_required_to, :to => :target, :type_cast => :to_i
      validates_numericality_of :fragment_size_required_from, :integer_only => true, :greater_than => 0
      validates_numericality_of :fragment_size_required_to,   :integer_only => true, :greater_than => 0

      delegate_attribute :library_type, :to => :target, :default => base::DEFAULT_LIBRARY_TYPE
      validates_inclusion_of :library_type, :in => base::LIBRARY_TYPES
    end)
  end

  module ClassMethods
    def delegate_validator
      self::RequestOptionsValidator
    end
  end

  def insert_size
    Aliquot::InsertSize.new(
      request_metadata.fragment_size_required_from,
      request_metadata.fragment_size_required_to
    )
  end

  def library_type
    request_metadata.library_type
  end
end
