#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2015 Genome Research Ltd.
class Api::Messages::BarcodeIO < Api::Base

  renders_model(::Asset)

  map_attribute_to_json_attribute(:uuid,'barcodable_uuid')
  map_attribute_to_json_attribute(:sti_type,'barcodable_type')
  map_attribute_to_json_attribute(:ean13_barcode,'machine_readable_barcode')
  map_attribute_to_json_attribute(:sanger_human_barcode,'human_readable_barcode')
  map_attribute_to_json_attribute(:barcode_type,'barcode_type')

end


