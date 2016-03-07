#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2011,2012 Genome Research Ltd.
class ::Io::Supplier < ::Core::Io::Base
  # This module adds the behaviour we require from the Supplier module.
  module ApiIoSupport
    def self.included(base)
      base.class_eval do
        # TODO: add any named scopes
        # TODO: add any associations
      end
    end

    # TODO: add any methods
  end

  set_json_root(:supplier)
  # set_eager_loading { |model| model }   # TODO: uncomment and add any named_scopes that do includes you need

  define_attribute_and_json_mapping(%Q{
            name  => name
           email  => email
         address  => address
    contact_name  => contact_name
    phone_number  => phone_number
             fax  => fax
    supplier_url  => url
    abbreviation  => abbreviation
  })
end
