# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2012,2013,2014,2015 Genome Research Ltd.

Given /^the barcode for the sample tube "([^\"]+)" is "([^\"]+)"$/ do |name, barcode|
  sample_tube = SampleTube.find_by(name: name) or raise StandardError, "Cannot find sample tube #{name.inspect}"
  sample_tube.update_attributes!(barcode: barcode)
end

Given /^tube "([^"]*)" has a public name of "([^"]*)"$/ do |name, public_name|
  Asset.find_by(name: name).update_attributes!(public_name: public_name)
end

Given /^(?:I have )?a phiX tube called "([^\"]+)"$/ do |name|
  FactoryGirl.create(:sample_tube, name: name, study: nil, project: nil)
end

Given /^(?:I have )?a (sample|library) tube called "([^\"]+)"$/ do |tube_type, name|
  FactoryGirl.create(:"#{ tube_type }_tube", name: name)
end

Given /^(?:I have )?a well called "([^\"]+)"$/ do |_name|
  sample = FactoryGirl.create(:sample)
  FactoryGirl.create(:well, sample: sample)
end

Then /^the name of (the .+) should be "([^\"]+)"$/ do |asset, name|
  assert_equal(name, asset.name)
end

Given /^there is an asset link between "([^"]*)" and "([^"]*)"$/ do |source, target|
  source_plate = Plate.find_by(name: source)
  target_plate = Plate.find_by(name: target)
  AssetLink.create_edge(source_plate, target_plate)
  target_plate.wells.each do |target_well|
    source_well = source_plate.wells.located_at(target_well.map_description).first
    Well::Link.create!(target_well: target_well, source_well: source_well, type: 'stock')
  end
end

Given /^the multiplexed library tube with ID (\d+) has a BigDecimal volume$/ do |id|
  MultiplexedLibraryTube.find(id).update_attributes!(volume: 8.76000000)
end
