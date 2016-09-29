#This file is part of SEQUENCESCAPE; it is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2007-2011,2012,2015 Genome Research Ltd.
class Io::SampleTube < Io::Asset
  set_model_for_input(::SampleTube)
  set_json_root(:sample_tube)
  set_eager_loading { |model| model.include_aliquots_for_api.include_scanned_into_lab_event }

  define_attribute_and_json_mapping(%Q{
                                  state  => state
                            purpose.name => purpose.name
                            purpose.uuid => purpose.uuid

                                 closed  => closed
                     concentration.to_f  => concentration
                            volume.to_f  => volume
                        scanned_in_date  => scanned_in_date
                                    role => label.prefix
                            purpose.name => label.text

                               aliquots  => aliquots

                                barcode  => barcode.number
                  barcode_prefix.prefix  => barcode.prefix
                two_dimensional_barcode  => barcode.two_dimensional
                          ean13_barcode  => barcode.ean13
  })
end
