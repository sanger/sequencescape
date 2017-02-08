# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2013,2015 Genome Research Ltd.

Given /^each well in "([^"]*)" has a DNA QC request$/ do |study_name|
  study = Study.find_by(name: study_name)
  request_type = RequestType.find_by(key: 'dna_qc')
  Well.find_each do |well|
    FactoryGirl.create(:request, request_type: request_type, asset: well, study: study, state: 'passed')
  end
end

Given /^each well in "([^"]*)" has a child sample tube$/ do |study_name|
  study = Study.find_by(name: study_name)
  Well.find_each do |well|
    well.children << FactoryGirl.create(:sample_tube)
  end
  RequestFactory.create_assets_requests(SampleTube.all, study)
end

Given /^each well in "([^"]*)" has a child well on a plate$/ do |study_name|
  study = Study.find_by(name: study_name)
  plate = Plate.create!(barcode: '44444', plate_purpose: PlatePurpose.find_by(name: 'Pulldown'))

  Well.find_each do |well|
    child_well = Well.create(map: well.map, plate: plate)
    well.children << child_well
  end
end
