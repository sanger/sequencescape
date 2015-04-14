#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2007-2011 Genome Research Ltd.
class ::Core::Io::Registry < ::Core::Registry
  # Looks up the I/O class by guessing at the name based on the model.  If it finds it it then registers
  # that class for the model class specified.
  def lookup_target_class_in_registry(model_class)
    in_current_registry = super
    return in_current_registry unless in_current_registry.nil?
    register(model_class, "::Io::#{model_class.name}".constantize)
  rescue NameError => exception
    nil
  end
  private :lookup_target_class_in_registry
end
