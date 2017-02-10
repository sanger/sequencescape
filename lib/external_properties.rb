# This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2012 Genome Research Ltd.
module ExternalProperties
  def get_external_value(key)
    key = key.to_s

    # that wil load all the properties , which is faster if we access more than one property
    # and if we pre-load them with eager loaging
    external_properties.each do |property|
      return property.value if property.key == key
    end
    nil
  end

  def self.included(base)
    base.send(:has_many, :external_properties, as: :propertied, dependent: :destroy)
  end
end
