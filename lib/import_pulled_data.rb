# This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2011,2012 Genome Research Ltd.
# require 'active_support'
module ImportPulledData
  # import into the database a list of object from a yaml file
  def self.import_from_yaml(file_name, names_map = {})
    object_parameters = YAML::load(File.read(file_name))
    import_from_parameters(object_parameters, names_map)
  end

  # create and save object from a parameters list
  # each parameter is a hash
  # :class => class name
  # :id => id
  # :attributes => a has with the attributes
  def self.import_from_parameters(object_parameters, names_map = {})
    object_parameters.map do |parameter|
      klass = parameter[:class].constantize
      object_id = parameter[:id]
      attributes = parameter[:attributes]
      # map name from table
      if name = attributes['name']
        attributes['name'] = names_map.fetch(name, name)
      end

      object = klass.new(attributes) { |r| r.id = object_id }
      if object.respond_to? :save_after_unmarshalling
        object.save_after_unmarshalling
      else
        object.save(validate: false)
      end
    end
  end
end
