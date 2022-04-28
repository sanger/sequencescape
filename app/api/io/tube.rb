# frozen_string_literal: true
# Controls API V1 IO for Tube
class Io::Tube < Io::Asset
  set_model_for_input(::Tube)
  set_json_root(:tube)
  set_eager_loading { |model| model.include_aliquots_for_api.include_scanned_into_lab_event }

  define_attribute_and_json_mapping(
    '
                                  state  => state
                            purpose.name => purpose.name
                            purpose.uuid => purpose.uuid

                                 closed  => closed
                     concentration.to_f  => concentration
                            volume.to_f  => volume
                        scanned_in_date  => scanned_in_date
                                    role => label.prefix
                            purpose.name => label.text

                       source_plate.uuid  => stock_plate.uuid
             source_plate.barcode_number  => stock_plate.barcode.number
                     source_plate.prefix  => stock_plate.barcode.prefix
    source_plate.two_dimensional_barcode  => stock_plate.barcode.two_dimensional
              source_plate.ean13_barcode  => stock_plate.barcode.ean13
            source_plate.machine_barcode  => stock_plate.barcode.machine
               source_plate.barcode_type  => stock_plate.barcode.type

                          barcode_number  => barcode.number
                                  prefix  => barcode.prefix
                 two_dimensional_barcode  => barcode.two_dimensional
                         machine_barcode  => barcode.machine
                           ean13_barcode  => barcode.ean13
                            barcode_type  => barcode.type

                               aliquots  => aliquots
  '
  )
end
