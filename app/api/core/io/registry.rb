# frozen_string_literal: true
class Core::Io::Registry < Core::Registry
  # Looks up the I/O class by guessing at the name based on the model.  If it finds it it then registers
  # that class for the model class specified.
  def lookup_target_class_in_registry(model_class)
    in_current_registry = super
    return in_current_registry unless in_current_registry.nil?

    register(model_class, "::Io::#{model_class.name}".constantize)
  rescue NameError => e
    nil
  end
  private :lookup_target_class_in_registry
end
