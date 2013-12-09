class Io::PlateForInbox < Core::Io::Base
  set_model_for_input(::PlateForInbox)
  set_json_root(:plate)

  define_attribute_and_json_mapping(%Q{

                                            name => name
                                            uuid => uuid
                                        barcode  => barcode.number
                          barcode_prefix.prefix  => barcode.prefix
                                  ean13_barcode  => barcode.ean13

                             plate_purpose_name  => plate_purpose.name

                                          state  => state
                                        priority => priority
                                      iteration  => iteration

                            source_plate.barcode  => stock_plate.barcode.number
              source_plate.barcode_prefix.prefix  => stock_plate.barcode.prefix
                      source_plate.ean13_barcode  => stock_plate.barcode.ean13
  })
end
