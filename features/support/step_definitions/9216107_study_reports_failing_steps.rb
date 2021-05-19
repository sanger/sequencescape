# frozen_string_literal: true

Given /^each well in "([^"]*)" has a child sample tube$/ do |study_name|
  study = Study.find_by(name: study_name)
  Well.find_each { |well| well.children << FactoryBot.create(:sample_tube) }
  RequestFactory.create_assets_requests(SampleTube.all, study)
end

Given /^each well in "([^"]*)" has a child well on a plate$/ do |study_name|
  study = Study.find_by(name: study_name)
  plate = FactoryBot.create(:plate, barcode: '44444', plate_purpose: PlatePurpose.find_by(name: 'Pulldown'))

  Well.find_each do |well|
    child_well = Well.create(map: well.map, plate: plate)
    well.children << child_well
  end
end
