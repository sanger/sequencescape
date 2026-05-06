# frozen_string_literal: true

class Core::Registry
  include ::Singleton

  RegistryError = Class.new(StandardError)
  AlreadyRegisteredError = Class.new(RegistryError)
  UnregisteredError = Class.new(RegistryError)

  def initialize
    @model_class_to_target = {}
  end

  def lookup_target_class_in_registry!(model_class)
    lookup_target_class_in_registry(model_class) or
      raise UnregisteredError, "Unable to locate for #{model_class.name.inspect}"
  end

  def lookup_target_class_through_model_hierarchy!(model_class, root_lookup_model_class = model_class)
    if model_class.nil? || (model_class == ActiveRecord::Base)
      raise UnregisteredError, "Unable to locate for #{root_lookup_model_class.name.inspect} (#{inspect})"
    end

    target_class = lookup_target_class_in_registry(model_class)
    return target_class unless target_class.nil?

    register(model_class, lookup_target_class_through_model_hierarchy!(model_class.superclass, root_lookup_model_class))
  end

  alias lookup lookup_target_class_through_model_hierarchy!
  private :lookup_target_class_in_registry!
  private :lookup_target_class_through_model_hierarchy!

  def lookup_for_class(model_class)
    lookup(model_class)
  end

  def lookup_for_object(model_instance)
    lookup(model_instance.class)
  end

  def inspect
    @model_class_to_target.to_h { |k, v| [k.to_s, v.to_s] }.inspect
  end

  def is_already_registered?(model_class)
    @model_class_to_target.key?(model_class.name)
  end
  private :is_already_registered?

  def register(model_class, io_class)
    unless model_class.name.match?(/^[A-Z][A-Za-z0-9:]+$/)
      raise StandardError, "Weird class (#{model_class.name.inspect} => #{model_class.inspect})"
    end

    @model_class_to_target[model_class.name] = io_class
  end
  private :register

  def deregister(model_class)
    @model_class_to_target.delete(model_class.name)
  end
  private :deregister

  def lookup_target_class_in_registry(model_class)
    @model_class_to_target[model_class.name]
  end
  private :lookup_target_class_in_registry
end
