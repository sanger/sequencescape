Then /^I should see dna qc table:$/ do |expected_results_table|
  actual_table = table(tableish('table#sortable_batches tr', 'td,th'))
  actual_table.map_column!('Qc') { |text| "" }
  expected_results_table.diff!(actual_table)
end

When /^I select "([^"]*)" for the first row of the plate$/ do |qc_result|
  1.upto(12) do |i|
    When %Q{I select "pass" from "Plate 1234567 QC status A#{i}"}
  end
end

Given /^a plate template exists$/ do
  Factory :plate_template
end

Given /^a robot exists$/ do
  robot = Factory :robot
  robot.robot_properties.create(:key => 'max_plates', :value => "21")
end

Then /^the manifest for study "([^"]*)" with plate "([^"]*)" should be:$/ do |study_name, plate_barcode, expected_results_table|
  study = Study.find_by_name(study_name)
  plate = Plate.find_by_barcode(plate_barcode)
  manifest = FasterCSV.parse(ManifestGenerator.generate_manifest_for_plate_ids([plate.id],study))
  manifest.shift(3)
  expected_results_table.diff!(manifest)
end

Given /^I have a plate "([^"]*)" in study "([^"]*)" with (\d+) samples in asset group "([^"]*)"$/ do |plate_barcode, study_name, number_of_samples,asset_group_name|
  study = Study.find_by_name(study_name)
  plate = Factory(:plate, :barcode => plate_barcode, :location => Location.find_by_name("Sample logistics freezer"))

  asset_group = study.asset_groups.find_by_name(asset_group_name) || study.asset_groups.create!(:name => asset_group_name)
  asset_group.assets << (1..number_of_samples.to_i).map do |index|
    Factory(:well, :name => "Well_#{plate_barcode}_#{index}", :plate => plate, :map_id => index).tap do |well|
      well.aliquots.create!(:sample => Factory(:sample, :name => "Sample_#{plate_barcode}_#{index}"),
                                              :study => study)
    end
  end
end

Given /^plate "([^"]*)" in study "([^"]*)" is in asset group "([^"]*)"$/ do |plate_barcode, study_name, asset_group_name|
  study = Study.find_by_name(study_name)
  plate = Plate.find_by_barcode(plate_barcode)
  asset_group = AssetGroup.find_or_create_by_name_and_study_id(asset_group_name, study.id)
  plate.wells.each do |well|
    asset_group.assets << well
  end
  asset_group.save!
end

Given /^I have a cherrypicking batch$/ do
  Given %Q{I have a cherrypicking batch with 96 samples}
end

Given /^I have a cherrypicking batch with (\d+) samples$/ do |number_of_samples|
  Given %Q{I am a "administrator" user logged in as "user"}
  Given %Q{I have a project called "Test project"}
  And %Q{project "Test project" has enough quotas}
  Given %Q{I have an active study called "Test study"}
  Given %Q{I have a plate "1234567" in study "Test study" with #{number_of_samples} samples in asset group "Plate asset group"}

  Given %Q{I have a Cherrypicking submission for asset group "Plate asset group"}
  Given %Q{I am on the show page for pipeline "Cherrypick"}

  When %Q{I check "Select DN1234567T for batch"}
  And %Q{I select "Create Batch" from "action_on_requests"}
  And %Q{I press "Submit"}
end

Given /^a robot exists with barcode "([^"]*)"$/ do |robot_barcode|
  robot = Factory :robot, :barcode => robot_barcode
  robot.robot_properties.create(:key => 'max_plates', :value => "21")
  robot.robot_properties.create(:key => 'SCRC1', :value => "1")
  robot.robot_properties.create(:key => 'SCRC2', :value => "2")
  robot.robot_properties.create(:key => 'SCRC3', :value => "3")
  robot.robot_properties.create(:key => 'DEST1', :value => "20")
end

When /^I complete the cherrypicking batch with "([^"]*)" plate purpose but dont release it$/ do |plate_purpose_name|
  When %Q{I follow "Start batch"}
  When %Q{I select "testtemplate" from "Plate Template"}
  When %Q{I select "#{plate_purpose_name}" from "Output plate purpose"}
  When %Q{I press "Next step"}
  And %Q{I press "Next step"}
  When %Q{I select "Genotyping freezer" from "Location"}
  And %Q{I press "Next step"}
end


When /^I complete the cherrypicking batch with "([^"]*)" plate purpose$/ do |plate_purpose_name|
  When %Q{I complete the cherrypicking batch with "#{plate_purpose_name}" plate purpose but dont release it}
  When %Q{I press "Release this batch"}
  Then %Q{I should see "Batch released"}
end

Given /^I have a cherrypicked plate with barcode "([^"]*)" and plate purpose "([^"]*)"$/ do |plate_barcode, plate_purpose_name|
  Given %Q{I have a Cherrypicking submission for asset group "Plate asset group"}
  Given %Q{I am on the show page for pipeline "Cherrypick"}
  When %Q{I check "Select DN1234567T for batch"}
  And %Q{I select "Create Batch" from "action_on_requests"}
  And %Q{I press "Submit"}
  Given %Q{a plate barcode webservice is available and returns "#{plate_barcode}"}
  When %Q{I complete the cherrypicking batch with "#{plate_purpose_name}" plate purpose but dont release it}
end

Given /^well "([^"]*)" on plate "([^"]*)" has a genotyping_done status of "([^"]*)"$/ do |well_description, plate_barcode, genotyping_status|
  plate = Plate.find_by_barcode(plate_barcode)
  well = plate.find_well_by_name(well_description)
  well.primary_aliquot.sample.external_properties.create!(:key => 'genotyping_done', :value => genotyping_status)
end


Given /^well "([^"]*)" has a genotyping status of "([^"]*)"$/ do |well_name, genotyping_status|
  well =Well.find_by_name(well_name)

  sample = Factory(:sample, :name => well_name.gsub(/ /,'_'))
  sample.external_properties.create!(:key => 'genotyping_done', :value => genotyping_status)
  sample.external_properties.create!(:key => 'genotyping_snp_plate_id')

  well.aliquots.clear
  well.aliquots.create!(:sample => sample)
end


Given /^I have a DNA QC submission for plate "([^"]*)"$/ do |plate_barcode|
  Given %{I have a "DNA QC" submission for plate "#{plate_barcode}" with project "Test project" and study "Study B"}
end

Given /^I have a "([^"]*)" submission for plate "([^"]*)" with project "([^"]*)" and study "([^"]*)"$/ do |submission_template_name,plate_barcode, project_name, study_name|
  plate = Plate.find_by_barcode(plate_barcode)
  project = Project.find_by_name(project_name)
  study = Study.find_by_name(study_name)

  # Maintain the order of the wells as though they have been submitted by the user, rather than
  # relying on the ordering within sequencescape.  Some of the plates are created with less than
  # the total wells needed (which is bad).
  wells = []
  plate.wells.walk_in_column_major_order { |well, _| wells << well }
  wells.compact!

  submission_template = SubmissionTemplate.find_by_name(submission_template_name)
  submission = submission_template.create_and_build_submission!(
    :study    => study,
    :project  => project,
    :workflow => Submission::Workflow.find_by_key('microarray_genotyping'),
    :user     => User.last,
    :assets   => wells
    )
  And %Q{1 pending delayed jobs are processed}
end


Given /^I have a Cherrypicking submission for asset group "([^"]*)"$/ do |asset_group_name|
  project = Project.find_by_name("Test project")
  study = Study.find_by_name("Test study")
  asset_group = AssetGroup.find_by_name(asset_group_name)

  submission_template = SubmissionTemplate.find_by_name('Cherrypick')
  submission = submission_template.create_and_build_submission!(
    :study => study,
    :project => project,
    :workflow => Submission::Workflow.find_by_key('microarray_genotyping'),
    :user => User.last,
    :assets => asset_group.assets
    )
  And %Q{1 pending delayed jobs are processed}
end

Given /^the internal QC plates are created$/ do
  When %Q{I follow "Pipelines"}
  When %Q{I follow "Create Plate Barcodes"}
  When %Q{I select "Pico Standard" from "Plate purpose"}
  And %Q{I select "xyz" from "Barcode printer"}
  And %Q{I fill in "User barcode" with "2470000100730"}
  And %Q{I press "Submit"}
  When %Q{I fill in "Source plates" with "1221234567841"}
  And %Q{I fill in "User barcode" with "2470000100730"}
  When %Q{I select "Working dilution" from "Plate purpose"}
  And %Q{I select "xyz" from "Barcode printer"}
  And %Q{I press "Submit"}
  When %Q{I fill in "Source plates" with "6251234567836"}
  And %Q{I fill in "User barcode" with "2470000100730"}
  When %Q{I select "Pico dilution" from "Plate purpose"}
  And %Q{I select "xyz" from "Barcode printer"}
  And %Q{I press "Submit"}
  When %Q{I fill in "Source plates" with "4361234567667"}
  And %Q{I fill in "User barcode" with "2470000100730"}
  When %Q{I select "Pico Assay Plates" from "Plate purpose"}
  And %Q{I select "xyz" from "Barcode printer"}
  And %Q{I press "Submit"}
  When %Q{I fill in "Source plates" with "6251234567836"}
  And %Q{I fill in "User barcode" with "2470000100730"}
  When %Q{I select "Gel Dilution Plates" from "Plate purpose"}
  And %Q{I select "xyz" from "Barcode printer"}
  And %Q{I press "Submit"}
  Then %Q{plate with barcode "4331234567653" is part of study "Test study"}
  And %Q{plate with barcode "4341234567737" is part of study "Test study"}
  And %Q{plate with barcode "1931234567771" is part of study "Test study"}
  Given %Q{5 pending delayed jobs are processed}

  # print sequenome barcode
  Given %Q{I am on the new Sequenom QC Plate page}
  When %Q{I fill in "User barcode" with "2470000100730"}
  And %Q{I fill in "Plate 1" with "6251234567836"}
  And %Q{I fill in "Number of Plates" with "1"}
  And %Q{I select "xyz" from "Barcode Printer"}
  And %Q{I press "Create new Plate"}
  And %Q{all pending delayed jobs are processed}
end

