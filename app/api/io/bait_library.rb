#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2011,2012 Genome Research Ltd.
class Io::BaitLibrary < Core::Io::Base
  set_model_for_input(::BaitLibrary)
  set_json_root(:bait_library)

  define_attribute_and_json_mapping(%Q{
    bait_library_supplier.name  => supplier.name
           supplier_identifier  => supplier.identifier
                          name  => name
                target_species  => target.species
        bait_library_type.name  => bait_library_type
  })
end
