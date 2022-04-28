# frozen_string_literal: true
# Controls API V1 IO for Qcable
class Io::Qcable < Core::Io::Base
  set_model_for_input(::Qcable)
  set_json_root(:qcable)

  set_eager_loading(&:include_for_json)

  define_attribute_and_json_mapping(
    '
                      state  => state
            stamp_qcable.bed => stamp_bed
                 stamp_index => stamp_index

         asset.barcode_number  => barcode.number
                 asset.prefix  => barcode.prefix
asset.two_dimensional_barcode  => barcode.two_dimensional
          asset.ean13_barcode  => barcode.ean13
        asset.machine_barcode  => barcode.machine
           asset.barcode_type  => barcode.type

  '
  )
end
