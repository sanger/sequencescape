# Any request involved in building a library should include this module that defines some of the
# most common behaviour, namely the library type and insert size information.
module Request::LibraryManufacture
  def self.included(base)
    base::Metadata.class_eval do
      attribute(:fragment_size_required_from, :required => true, :integer => true)
      attribute(:fragment_size_required_to,   :required => true, :integer => true)
      attribute(:library_type, { :with_method => :valid_library_types, :default=>'Standard',:default_lookup => :default_library_type, :required => true })

      def valid_library_types
        valid_types = owner.request_type.library_types.map(&:name)
        valid_types.include?(library_type).tap do |valid|
          errors.add(:library_type,
            "'#{library_type}' is not a valid library type for #{owner.request_type.name}: valid types '#{valid_types.join("','")}'"
          ) unless valid
        end
      end

      def default_library_type
        owner.request_type.default_library_type.name
      end

    end

    base.class_eval do
      extend ClassMethods
    end

    base.const_set(:RequestOptionsValidator, Class.new(DelegateValidation::Validator) do
      delegate_attribute :fragment_size_required_from, :fragment_size_required_to, :to => :target, :type_cast => :to_i
      validates_numericality_of :fragment_size_required_from, :integer_only => true, :greater_than => 0
      validates_numericality_of :fragment_size_required_to,   :integer_only => true, :greater_than => 0
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
