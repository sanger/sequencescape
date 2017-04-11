# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2012,2015 Genome Research Ltd.

class ::Core::Registry
  include ::Singleton
  include ::Core::Logging

  RegistryError          = Class.new(StandardError)
  AlreadyRegisteredError = Class.new(RegistryError)
  UnregisteredError      = Class.new(RegistryError)

  def initialize
    @model_class_to_target = {}
  end

  def lookup_target_class_in_registry!(model_class)
    lookup_target_class_in_registry(model_class) or raise UnregisteredError, "Unable to locate for #{model_class.name.inspect}"
  end

  def lookup_target_class_through_model_hierarchy!(model_class, root_lookup_model_class = model_class)
    raise UnregisteredError, "Unable to locate for #{root_lookup_model_class.name.inspect} (#{inspect})" if model_class.nil? or ActiveRecord::Base == model_class

    target_class = lookup_target_class_in_registry(model_class)
    return target_class unless target_class.nil?

    register(model_class, lookup_target_class_through_model_hierarchy!(model_class.superclass, root_lookup_model_class))
  end

  alias_method(:lookup, :lookup_target_class_through_model_hierarchy!)
  private :lookup_target_class_in_registry!
  private :lookup_target_class_through_model_hierarchy!

  def lookup_for_class(model_class)
    lookup(model_class)
  end

  def lookup_for_object(model_instance)
    lookup(model_instance.class)
  end

  def inspect
    Hash[@model_class_to_target.map { |k, v| [k.to_s, v.to_s] }].inspect
  end

  def is_already_registered?(model_class)
    @model_class_to_target.key?(model_class.name)
  end
  private :is_already_registered?

  def register(model_class, io_class)
    raise StandardError, "Weird class (#{model_class.name.inspect} => #{model_class.inspect})" unless model_class.name =~ /^[A-Z][A-Za-z0-9:]+$/
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
