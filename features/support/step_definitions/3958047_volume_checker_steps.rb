# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2013,2015 Genome Research Ltd.

Given /^all plate volume check files are processed$/ do
  PlateVolume.process_all_volume_check_files
end

Given /^study "([^"]*)" has a plate "([^"]*)" setup for volume checking$/ do |study_name, plate_barcode|
  study = Study.find_by(name: study_name) or raise StandardError, "Cannot find study #{study_name.inspect}"
  plate = Plate.create!(barcode: plate_barcode, location: Location.find_by(name: 'Sample logistics freezer'))

  (1..96).map do |i|
    plate.wells.create!(map: Map.find_by(description: Map.vertical_position_to_description(i, 8), asset_size: plate.size))
  end

  RequestFactory.create_assets_requests(plate.wells, study)
end
