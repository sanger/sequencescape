class Io::Tube < Io::Asset
  set_model_for_input(::Tube)
  set_json_root(:tube)
  set_eager_loading { |model| model.include_aliquots.include_scanned_into_lab_event }

  define_attribute_and_json_mapping(%Q{
                                  state  => state
                            purpose.name => purpose.name
                            purpose.uuid => purpose.uuid

                                 closed  => closed
                          concentration  => concentration
                                 volume  => volume
                        scanned_in_date  => scanned_in_date

                       stock_plate.uuid  => stock_plate.uuid
                    stock_plate.barcode  => stock_plate.barcode.number
      stock_plate.barcode_prefix.prefix  => stock_plate.barcode.prefix
    stock_plate.two_dimensional_barcode  => stock_plate.barcode.two_dimensional
              stock_plate.ean13_barcode  => stock_plate.barcode.ean13
               stock_plate.barcode_type  => stock_plate.barcode.type

                               aliquots  => aliquots
  })
end
