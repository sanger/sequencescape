# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2014,2015 Genome Research Ltd.

class Io::Qcable < Core::Io::Base
  set_model_for_input(::Qcable)
  set_json_root(:qcable)

  set_eager_loading { |model| model.include_for_json }

  define_attribute_and_json_mapping("
                      state  => state
            stamp_qcable.bed => stamp_bed
                 stamp_index => stamp_index

         asset.barcode_number  => stock_plate.barcode.number
                 asset.prefix  => stock_plate.barcode.prefix
asset.two_dimensional_barcode  => stock_plate.barcode.two_dimensional
          asset.ean13_barcode  => stock_plate.barcode.ean13
        asset.machine_barcode  => stock_plate.barcode.machine
           asset.barcode_type  => stock_plate.barcode.type

  ")
end
