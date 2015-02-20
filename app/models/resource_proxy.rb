#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2007-2011 Genome Research Ltd.
class ResourceProxy
  def initialize(resource, resource_class)
    @resource_id = case resource
                  when String
                    resource
                  when Integer
                    resource
                  when Hash
                    resource["id"]  #|| resource[:id]
                  when NilClass
                    nil
                  else
                    @object = resource
                    resource.id
                  end
    @resource_class = resource_class
  end

  def id
    @resource_id
  end

  def object
    @object ||= @resource_class.find(@resource_id)
  end

  def set_object(object)
    @object = object
  end

  def loaded?
    @object ? true : false
  end
end
