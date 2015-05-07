#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2007-2011,2011,2013,2014 Genome Research Ltd.
class Io::Plate < Io::Asset
  set_model_for_input(::Plate)
  set_json_root(:plate)
  set_eager_loading { |model| model.include_plate_metadata.include_plate_purpose }

  define_attribute_and_json_mapping(%Q{
                                           size <=> size
                             plate_purpose.name  => plate_purpose.name
                         plate_purpose.lifespan  => plate_purpose.lifespan

                                          state  => state
                                      iteration  => iteration
                                          pools  => pools
                                  pre_cap_groups => pre_cap_groups
                                            role => label.prefix
                                    purpose.name => label.text
                                   location.name => location
                                        priority => priority

                               source_plate.uuid  => stock_plate.uuid
                            source_plate.barcode  => stock_plate.barcode.number
              source_plate.barcode_prefix.prefix  => stock_plate.barcode.prefix
            source_plate.two_dimensional_barcode  => stock_plate.barcode.two_dimensional
                      source_plate.ean13_barcode  => stock_plate.barcode.ean13
                       source_plate.barcode_type  => stock_plate.barcode.type

                                         barcode  => barcode.number
                           barcode_prefix.prefix  => barcode.prefix
                         two_dimensional_barcode  => barcode.two_dimensional
                                   ean13_barcode  => barcode.ean13
                                    barcode_type  => barcode.type
  })
end
