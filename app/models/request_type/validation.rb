module RequestType::Validation

  # def self.included(base)
  #   base.class_eval do
  #     delegate :delegate_validator, :to => :request_class
  #   end
  # end

  def delegate_validator
    DelegateValidation::CompositeValidator::CompositeValidator(request_class.delegate_validator,request_type_validator)
  end

  def request_type_validator
    request_type = self
    Class.new(LibraryTypeValidator) do
      validates_inclusion_of :library_type, :in => request_type.library_types.map(&:name), :if => :library_types_present?
      delegate_attribute :library_type, :to => :target, :default => request_type.default_library_type.name if request_type.library_types.present?
    end.tap do |sub_class|
      sub_class.write_inheritable_attribute(:request_type, request_type)
    end
  end

  class LibraryTypeValidator < DelegateValidation::Validator
    class_inheritable_reader :request_type
    write_inheritable_attribute :request_type, nil

    def library_types_present?
      request_type.library_types.present?
    end
  end
end
