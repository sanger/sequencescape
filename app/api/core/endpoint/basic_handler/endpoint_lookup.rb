#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2007-2011,2011,2012 Genome Research Ltd.
module Core::Endpoint::BasicHandler::EndpointLookup
  EndpointError = Class.new(StandardError)
  MissingEndpoint = Class.new(EndpointError)


  def endpoint_for(model, root = model)
    raise EndpointError, "Incorrect hierarchy for #{root.inspect}"     if model.nil?
    raise MissingEndpoint, "No endpoint for the model #{root.inspect}" if model == ActiveRecord::Base

    endpoint_name = [ 'Endpoints', model.name.pluralize ].join('::')

    begin
      endpoint_name.constantize
    rescue NameError => exception
      # Some performance improvement can be made by storing the class that is found for those
      # that are missing.  Meaning the next time we shouldn't be coming through this path.
      cache_endpoint_as(endpoint_name, endpoint_for(model.superclass, root))
    end
  end
  private :endpoint_for

  def cache_endpoint_as(endpoint_name, endpoint)
    root, *rest   = endpoint_name.split('::')
    leaf          = rest.pop
    module_parent = rest.inject(root.constantize, &method(:constant_lookup))
    constant_lookup(module_parent, leaf, endpoint)
  end
  private :cache_endpoint_as

  def constant_lookup(current, module_name, value = nil)
    # NOTE: Do not use const_get and rescue NameError here because that causes Rails to load the model
    return current.const_get(module_name) if current.const_defined?(module_name,false)
    current.const_set(module_name, value || Module.new)
  end
  private :constant_lookup

  def endpoint_for_object(model_instance)
    endpoint_for(model_instance.class)
  end
  private :endpoint_for_object

  def endpoint_for_class(model_class)
    endpoint_for(model_class)
  end
  private :endpoint_for_class
end

