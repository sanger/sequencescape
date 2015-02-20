#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2011 Genome Research Ltd.
class ::Io::BarcodePrinter < ::Core::Io::Base
  set_model_for_input(::BarcodePrinter)
  set_json_root(:barcode_printer)
  set_eager_loading { |model| model.include_barcode_printer_type }

  define_attribute_and_json_mapping(%Q{
                                    name  => name
                                  active  => active
                             service_url  => service.url
               barcode_printer_type.name  => type.name
    barcode_printer_type.printer_type_id  => type.layout
  })
end
