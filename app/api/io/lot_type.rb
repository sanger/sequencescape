# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2014,2015 Genome Research Ltd.

class ::Io::LotType < ::Core::Io::Base
  set_model_for_input(::LotType)
  set_json_root(:lot_type)

  define_attribute_and_json_mapping(%Q{
                                           name => name
                                 template_class => template_class
                            target_purpose.name => qcable_name
                                   printer_type => printer_type
  })
end
