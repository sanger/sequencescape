# frozen_string_literal: true
# Any request involved in building a library should include this module that defines some of the
# most common behaviour, namely the library type and insert size information.
module Request::LibraryManufacture
  def self.included(base)
    base::Metadata.class_eval do
      custom_attribute(:fragment_size_required_from, required: true, integer: true, on: :create, minimum: 1)
      custom_attribute(:fragment_size_required_to, required: true, integer: true, on: :create, minimum: 1)
      custom_attribute(:library_type, required: true, validator: true, selection: true, on: :create)
    end

    base.class_eval { extend ClassMethods }

    base.const_set(
      :RequestOptionsValidator,
      Class.new(DelegateValidation::Validator) do
        delegate_attribute :fragment_size_required_from, :fragment_size_required_to, to: :target, type_cast: :to_i
        validates :fragment_size_required_from, numericality: { integer_only: true, greater_than: 0 }
        validates :fragment_size_required_to, numericality: { integer_only: true, greater_than: 0 }
      end
    )
  end

  module ClassMethods
    def delegate_validator
      self::RequestOptionsValidator
    end
  end

  def insert_size
    Aliquot::InsertSize.new(request_metadata.fragment_size_required_from, request_metadata.fragment_size_required_to)
  end

  delegate :library_type, to: :request_metadata
end
