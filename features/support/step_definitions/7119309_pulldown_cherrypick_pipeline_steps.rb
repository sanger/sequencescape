# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2012,2013,2014,2015 Genome Research Ltd.

Given(/^plate "([^"]*)" with (\d+) samples in study "([^"]*)" has a "([^"]*)" submission$/) do |plate_barcode, number_of_samples, study_name, submission_name|
  step(%Q{I have a plate "#{plate_barcode}" in study "#{study_name}" with #{number_of_samples} samples in asset group "Plate asset group #{plate_barcode}"})
  step(%Q{plate "#{plate_barcode}" has concentration results})
  step(%Q{plate "#{plate_barcode}" has measured volume results})

  # Maintain the order of the wells as though they have been submitted by the user, rather than
  # relying on the ordering within sequencescape.  Some of the plates are created with less than
  # the total wells needed (which is bad).
  wells = []
  Plate.find_by(barcode: plate_barcode).wells.walk_in_column_major_order { |well, _| wells << well }
  wells.compact!

  study = Study.find_by(name: study_name)
  project = Project.find_by(name: 'Test project')
  # we need to set the study on aliquots
  wells.each do |well|
    well.aliquots.each do |a|
      a.update_attributes!(study_id: study.id, project_id: project.id)
    end
  end

  submission_template = SubmissionTemplate.find_by(name: submission_name)
  submission = submission_template.create_and_build_submission!(
    study: study,
    project: project,
    workflow: Submission::Workflow.find_by(key: 'short_read_sequencing'),
    user: User.last,
    assets: wells,
    request_options: { :multiplier => { '1' => '1', '3' => '1' }, 'read_length' => '100', 'fragment_size_required_to' => '400', 'fragment_size_required_from' => '300', 'library_type' => 'Standard' }
    )
  step('1 pending delayed jobs are processed')
end

Given(/^plate "([^"]*)" with (\d+) samples in study "([^"]*)" has a "([^"]*)" submission for cherrypicking$/) do |plate_barcode, number_of_samples, study_name, submission_name|
  step(%Q{I have a plate "#{plate_barcode}" in study "#{study_name}" with #{number_of_samples} samples in asset group "Plate asset group #{plate_barcode}"})
  step(%Q{plate "#{plate_barcode}" has concentration results})

  # Maintain the order of the wells as though they have been submitted by the user, rather than
  # relying on the ordering within sequencescape.  Some of the plates are created with less than
  # the total wells needed (which is bad).
  wells = []
  Plate.find_by(barcode: plate_barcode).wells.walk_in_column_major_order { |well, _| wells << well }
  wells.compact!

  submission_template = SubmissionTemplate.find_by(name: submission_name)
  submission = submission_template.create_and_build_submission!(
    study: Study.find_by(name: study_name),
    project: Project.find_by(name: 'Test project'),
    workflow: Submission::Workflow.find_by(key: 'short_read_sequencing'),
    user: User.last,
    assets: wells
    )
  step('1 pending delayed jobs are processed')
end

Given(/^plate "([^"]*)" with (\d+) samples in study "([^"]*)" exists$/) do |plate_barcode, number_of_samples, study_name|
  step(%Q{I have a plate "#{plate_barcode}" in study "#{study_name}" with #{number_of_samples} samples in asset group "Plate asset group #{plate_barcode}"})
  step(%Q{plate "#{plate_barcode}" has concentration results})
  step(%Q{plate "#{plate_barcode}" has measured volume results})
end

Given(/^plate "([^"]*)" has concentration results$/) do |plate_barcode|
  plate = Plate.find_by(barcode: plate_barcode)
  plate.wells.each_with_index do |well, index|
    well.well_attribute.update_attributes!(concentration: index * 40)
  end
end

Given(/^plate "([^"]*)" has nonzero concentration results$/) do |plate_barcode|
 step(%Q{plate "#{plate_barcode}" has concentration results})

  plate = Plate.find_by(barcode: plate_barcode)
  plate.wells.each_with_index do |well, _index|
    if well.well_attribute.concentration == 0.0
      well.well_attribute.update_attributes!(concentration: 1)
    end
  end
end

Given(/^plate "([^\"]+)" has no concentration results$/) do |plate_barcode|
  plate = Plate.find_by(barcode: plate_barcode) or raise StandardError, "Cannot find plate #{plate_barcode.inspect}"
  plate.wells.each do |well|
    well.well_attribute.update_attributes!(concentration: nil)
  end
end

Given(/^plate "([^"]*)" has measured volume results$/) do |plate_barcode|
  plate = Plate.find_by(barcode: plate_barcode)
  plate.wells.each_with_index do |well, index|
    well.well_attribute.update_attributes!(measured_volume: index * 11)
  end
end

def interpreter_is?(interpreter)
  return true if interpreter.blank?
  defined?(JRuby).nil? == (interpreter == 'MRI')
end

Then /^I should see the (MRI |JRuby |)cherrypick worksheet table:$/ do |interpreter, expected_results_table|
  if interpreter_is?(interpreter.strip)
    actual_table = table(fetch_table('table.plate_layout'))
    expected_results_table.column_names.each do |column_name|
      expected_results_table.map_column!(column_name.to_s) { |text| text.squish }
    end
    expected_results_table.diff!(actual_table)
  end
end

When /^I look at the pulldown report for the batch it should be:$/ do |expected_results_table|
  expected_results_table.diff!(CSV.parse(page.source).collect { |r| r.collect { |c| c ? c : '' } })
end

Given(/^I have a tag group called "([^"]*)" with (\d+) tags$/) do |tag_group_name, number_of_tags|
  oligos = %w(ATCACG CGATGT TTAGGC TGACCA)
  tag_group = TagGroup.create!(name: tag_group_name)
  tags = []
  1.upto(number_of_tags.to_i) do |i|
    Tag.create!(oligo: oligos[(i - 1) % oligos.size], map_id: i, tag_group_id: tag_group.id)
  end
end

Then /^the default plates to wells table should look like:$/ do |expected_results_table|
  actual_table = table(fetch_table('table.plate').collect { |row| row.collect { |cell| cell[/^(Tag [\d]+)|(\w+)/] } })

  expected_results_table.diff!(actual_table)
end

When /^I set (PacBioLibraryTube|Plate|Sample|Multiplexed Library|Library|Pulldown Multiplexed Library) "([^"]*)" to be in freezer "([^"]*)"$/ do |_asset_type, plate_barcode, freezer_name|
  asset = Asset.find_from_machine_barcode(plate_barcode)
  location = Location.find_by(name: freezer_name)
  asset.update_attributes!(location: location)
end

Given(/^I have a pulldown batch$/) do
  step('plate "1234567" with 8 samples in study "Test study" has a "Cherrypicking for Pulldown - Pulldown Multiplex Library Preparation - HiSeq Paired end sequencing" submission')
  step('plate "222" with 8 samples in study "Study A" has a "Cherrypicking for Pulldown - Pulldown Multiplex Library Preparation - HiSeq Paired end sequencing" submission')
  step('plate "1234567" has nonzero concentration results')
  step('plate "1234567" has measured volume results')
  step('plate "222" has nonzero concentration results')
  step('plate "222" has measured volume results')

  step('the plate barcode webservice returns "99999"')
  step('I am on the show page for pipeline "Cherrypicking for Pulldown"')
  step('I check "Select DN1234567T for batch"')
  step('I check "Select DN222J for batch"')
  step('I select "Create Batch" from the first "action_on_requests"')
  step('I press "Submit"')
  step('I follow "Cherrypick Group By Submission"')
  step('I select "Pulldown Aliquot" from "Plate Purpose"')
  step('I press "Next step"')
  step('I press "Release this batch"')
  step('I set Plate "1220099999705" to be in freezer "Pulldown freezer"')
  step('I am on the show page for pipeline "Pulldown Multiplex Library Preparation"')
  step('I check "Select DN99999F for batch"')
  step('I press "Submit"')
end

Given(/^I have 2 pulldown plates$/) do
  step('plate "1234567" with 1 samples in study "Test study" has a "Cherrypicking for Pulldown - Pulldown Multiplex Library Preparation - HiSeq Paired end sequencing" submission')
  step('plate "1234567" has nonzero concentration results')
  step('plate "1234567" has measured volume results')

  step('the plate barcode webservice returns "99999"')
  step('I am on the show page for pipeline "Cherrypicking for Pulldown"')
  step('I check "Select DN1234567T for batch"')
  step('I select "Create Batch" from the first "action_on_requests"')
  step('I press "Submit"')
  step('I follow "Cherrypick Group By Submission"')
  step('I select "Pulldown Aliquot" from "Plate Purpose"')
  step('I press "Next step"')
  step('I press "Release this batch"')
  step('I set Plate "1220099999705" to be in freezer "Pulldown freezer"')

  step('plate "222" with 1 samples in study "Study A" has a "Cherrypicking for Pulldown - Pulldown Multiplex Library Preparation - HiSeq Paired end sequencing" submission')
  step('plate "222" has nonzero concentration results')
  step('plate "222" has measured volume results')
  step('the plate barcode webservice returns "88888"')
  step('I am on the show page for pipeline "Cherrypicking for Pulldown"')
  step('I check "Select DN222J for batch"')
  step('I press "Submit"')
  step('I follow "Cherrypick Group By Submission"')
  step('I select "Pulldown Aliquot" from "Plate Purpose"')
  step('I press "Next step"')
  step('I press "Release this batch"')
  step('I set Plate "1220088888782" to be in freezer "Pulldown freezer"')
end

Given(/^all library tube barcodes are set to know values$/) do
  PulldownMultiplexedLibraryTube.all.each_with_index do |tube, index|
    tube.update_attributes!(barcode: (index + 1).to_s)
  end
end

Then /^the worksheet for the last batch should be:$/ do |expected_results_table|
  expected_results_table.diff!(table(fetch_table('table#pulldown_worksheet_details')))
end

Then /^library "([^"]*)" should have (\d+) sequencing requests$/ do |library_barcode, number_of_sequencing_requests|
  library = Asset.find_from_machine_barcode(library_barcode) or raise "Cannot find library with barcode #{library_barcode.inspect}"
  assert_equal number_of_sequencing_requests.to_i, SequencingRequest.count(conditions: ["asset_id = #{library.id}"])
end

Given(/^the CherrypickForPulldownPipeline pipeline has a max batch size of (\d+)$/) do |max_size|
  pipeline = Pipeline.find_by(name: 'Cherrypicking for Pulldown')
  pipeline.update_attributes!(max_size: max_size)
end

Given(/^I have a plate "([^"]*)" with the following wells:$/) do |plate_barcode, well_details|
  plate = FactoryGirl.create :plate, barcode: plate_barcode
  well_details.hashes.each do |well_detail|
    well = Well.create!(map: Map.find_by(description: well_detail[:well_location], asset_size: 96), plate: plate)
    well.well_attribute.update_attributes!(concentration: well_detail[:measured_concentration], measured_volume: well_detail[:measured_volume])
  end
end

Given(/^I have a "([^"]*)" submission with 2 plates$/) do |submission_template_name|
    project = FactoryGirl.create :project
    study = FactoryGirl.create :study
    plate_1 = FactoryGirl.create :plate, barcode: '333'
    plate_2 = FactoryGirl.create :plate, barcode: '222'
    [plate_1, plate_2].each do |plate|
      Well.create!(map_id: 1, plate: plate)
    end

    submission_template = SubmissionTemplate.find_by(name: submission_template_name)

    submission = submission_template.create_and_build_submission!(
      study: study,
      project: project,
      workflow: Submission::Workflow.find_by(key: 'short_read_sequencing'),
      user: User.last,
      assets: Well.all,
      request_options: { :multiplier => { '1' => '1', '3' => '1' }, 'read_length' => '100', 'fragment_size_required_to' => '300', 'fragment_size_required_from' => '250', 'library_type' => 'Standard' }
      )
    step('1 pending delayed jobs are processed')
end

When /^the last batch is sorted in row order$/ do
  order = Batch.last.batch_requests.map { |br| br.request.asset.map.row_order }.sort
  Batch.last.batch_requests.map { |br| br.update_attributes!(position: order.index(br.request.asset.map.row_order)) }
end

When /^the last batch is sorted in row and plate order$/ do
  source = Batch.last.batch_requests.group_by { |br| br.request.asset.plate.id }
  order = source.sort_by(&:first).map { |_plate, br| br.sort_by { |br| br.request.asset.map.row_order }.map(&:id) }.flatten
  Batch.last.batch_requests.map { |br| br.update_attributes!(position: order.index(br.id)) }
end
