# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2012,2013,2015,2016 Genome Research Ltd.

Given /^study "([^\"]*)" has property "([^\"]*)" set to "([^\"]*)"$/ do |study_name, property_name, value|
  study = Study.first(conditions: { name: study_name }) or raise StandardError, "Study '#{study_name}' does not exist"
  study.properties.set(property_name.downcase.gsub(/[^a-z0-9]+/, '_'), value)
end

Given /^I have a study called "([^\"]*)"$/ do |study|
  FactoryGirl.create :study, name: study, state: 'pending'
end

Given /^I have a study called "([^\"]*)" that requires ethical approval and has HMDMC approval number "(.*?)"$/ do |study, number|
  study = FactoryGirl.create :study, name: study
  study.study_metadata.contains_human_dna = 'Yes'
  study.study_metadata.contaminated_human_dna = 'No'
  study.study_metadata.commercially_available = 'No'
  study.study_metadata.hmdmc_approval_number = number
  study.save
end

Given /^a study "(.*?)" is pending$/ do |study|
  Study.find_by(name: study).reset!
end

Given /^study "([^\"]*)" status is "([^\"]*)"$/ do |study, status|
  proj = Study.find_by(name: study)
  status == 'active' ? proj.activate! : proj.deactivate!
  proj.save
end

Given /^I have an "([^\"]*)" study called "([^\"]*)"$/ do |status, study|
  step %Q{I have a study called "#{study}"}
  step %Q{study "#{study}" status is "#{status}"}
end

Given /^study "([^\"]*)" has samples registered$/ do |study|
  proj = Study.find_by(name: study)
  user = User.find_by login: 'user'
  new_sample_group = FactoryGirl.create :sample_group, name: 'new_sample_group', user: user, study: proj
  samples = {
    '0' => {
      'name' => 'SUPPLIER SAMPLE NAME',
      'sample_metadata_attributes' => {
        'organism' => 'COHORT',
        'gc_content' => 'Neutral',
        'scientific_rationale' => 'GEOGRAPHICAL REGION',
        'concentration' => 'COUNTRY OF ORIGIN'
      }
    },
    '1' => {
      'name' => 'Sample_987654',
      'sample_metadata_attributes' => {
        'organism' => 'BSP',
        'gc_content' => 'Neutral',
        'scientific_rationale' => 'north ',
        'concentration' => '123456'
      }
    }
  }
  sample_registrar = SampleRegistrar.new
  sample_registrar.create('samples' => samples, 'study_id' => proj.id, 'sample_group' => { 'id' => new_sample_group.id.to_s }, 'current_user' => user)
end

Given /^study "([^\"]*)" has assets registered$/ do |study|
  proj = Study.find_by(name: study)
  user = User.find_by login: 'user'
  new_sample_group = FactoryGirl.create :asset_group, name: 'new_asset_group', user: user, study: proj
end

Given /^the following user records$/ do |table|
   table.hashes.each do |hash|
     if usr = User.find_by(login: hash['login'])
       usr.first_name = hash['first_name']
       usr.last_name = hash['last_name']
     else
       usr = FactoryGirl.create(:user, hash)
     end
       usr.save
   end
end

Given /^user "([^\"]*)" is an? "([^\"]*)" of study "([^\"]*)"$/ do |login, role_name, study|
  proj = Study.find_by(name: study)
  role = Role.find_by(name: role_name, authorizable_type: 'Study', authorizable_id: proj.id)
  if role.nil?
    role = FactoryGirl.create :role, name: role_name, authorizable_type: 'Study',
                                     authorizable_id: proj.id, created_at: Time.now, updated_at: Time.now
  end
  usr = User.find_by(login: login)
  usr.roles << role
  usr.save
end

Given /^I have an active study called "([^\"]*)"$/ do |study_name|
  step %Q{I have a study called "#{study_name}"}
  step %Q{study "#{study_name}" status is "active"}
end

Given /^I am visiting "([^\"]*)" page with ID "([^\"]*)" homepage$/ do |_page, id|
  visit study_workflow_path(Study.find(id), Submission::Workflow.first)
end

Given /^I am visiting study "([^\"]*)" homepage$/ do |study_name|
  study = Study.find_by(name: study_name)
  visit study_workflow_path(study, Submission::Workflow.first)
end

And /^the study have a workflow$/ do
  FactoryGirl.create :submission_workflow
end

def GivenFixedStudyMetadata(attribute, value, regexp)
  Given(regexp) do |name|
    study = Study.find_by(name: name) or raise StandardError, "There appears to be no study named '#{name}'"
    study.study_metadata.send(:"#{ attribute }=", value)
    study.save!
  end
end

GivenFixedStudyMetadata(:contaminated_human_dna,  Study::YES, /^the study "([^\"]+)" has samples contaminated with human DNA$/)
GivenFixedStudyMetadata(:contaminated_human_dna,  Study::NO,  /^the study "([^\"]+)" does not have any samples contaminated with human DNA$/)
GivenFixedStudyMetadata(:remove_x_and_autosomes,  Study::YES, /^the study "([^\"]+)" has samples which need x and autosome data removed$/)
GivenFixedStudyMetadata(:remove_x_and_autosomes,  Study::NO,  /^the study "([^\"]+)" does not have any samples which need x and autosome data removed$/)
GivenFixedStudyMetadata(:contains_human_dna,      Study::YES, /^the study "([^\"]+)" contains human DNA$/)
GivenFixedStudyMetadata(:contains_human_dna,      Study::NO,  /^the study "([^\"]+)" does not contain human DNA$/)
GivenFixedStudyMetadata(:commercially_available,  Study::YES, /^the study "([^\"]+)" contains samples commercially available$/)
GivenFixedStudyMetadata(:commercially_available,  Study::NO,  /^the study "([^\"]+)" does not contain samples commercially available$/)

def GivenStudyMetadata(attribute, regexp)
  Given(regexp) do |name, value|
    study = Study.find_by(name: name) or raise StandardError, "There appears to be no study named '#{name}'"
    study.study_metadata.send(:"#{ attribute }=", value.blank? ? nil : value)
    study.save!
  end
end

GivenStudyMetadata(:data_release_strategy,      /^the study "([^\"]+)" has an? (open|managed) data release strategy$/)
GivenStudyMetadata(:data_release_timing,        /^the study "([^\"]+)" data release timing is (standard)$/)
GivenStudyMetadata(:study_ebi_accession_number, /^the study "([^\"]+)" has the accession number "([^\"]+)"$/)

def GivenStudyTypeStudyMetadata(attribute, regexp)
  Given(regexp) do |name, value|
    study = Study.find_by(name: name) or raise StandardError, "There appears to be no study named '#{name}'"
    study_type = StudyType.find_by(name: value) or raise StandardError, "Study type not valid: '#{value}'"
    study.study_metadata.send(:"#{ attribute }=", study_type)
    study.save!
  end
end

Given /^the study "([^\"]+)" belongs to the program "([^\"]*)"$/ do |study_name, program_name|
  study = Study.find_by(name: study_name) or raise StandardError, "There appears to be no study named '#{study_name}'"
  program = Program.find_by(name: program_name) or raise StandardError, "Program not valid: '#{program_name}'"
  study.study_metadata.program = program
  study.save!
end

GivenStudyTypeStudyMetadata(:study_type,              /^the study "([^\"]+)" is a "([^\"]*)" study$/)

def GivenStudyDataReleaseTypeStudyMetadata(attribute, regexp)
  Given(regexp) do |name, value|
    study = Study.find_by(name: name) or raise StandardError, "There appears to be no study named '#{name}'"
    study_type_dr = DataReleaseStudyType.find_by(name: value) or raise StandardError, "Data Release Study type not valid: '#{value}'"
    study.study_metadata.send(:"#{ attribute }=", study_type_dr)
    study.save!
  end
end

GivenStudyDataReleaseTypeStudyMetadata(:data_release_study_type, /^the study "([^\"]+)" is a "([^\"]+)" study for data release$/)

def GivenReferenceGenomeStudyMetadata(attribute, regexp)
  Given(regexp) do |name, value|
    study = Study.find_by(name: name) or raise StandardError, "There appears to be no study named '#{name}'"
    ref_genome = ReferenceGenome.find_by(name: value) or raise StandardError, "Study type not valid: '#{value}'"
    study.study_metadata.send(:"#{ attribute }=", ref_genome)
    study.save!
  end
end

def GivenFacultySponsor(attribute, regexp)
  Given(regexp) do |name, value|
    study = Study.find_by(name: name) or raise StandardError, "There appears to be no study named '#{name}'"
    faculty_sponsor = FacultySponsor.create!(name: value)
    study.study_metadata.send(:"#{ attribute }=", faculty_sponsor)
    study.save!
  end
end

GivenFacultySponsor(:faculty_sponsor,                /^the faculty sponsor for study "([^\"]+)" is "([^\"]+)"$/)

GivenReferenceGenomeStudyMetadata(:reference_genome, /^the reference genome for study "([^\"]+)" is "([^\"]+)"$/)

GivenStudyMetadata(:dac_policy, /^the policy for study "([^\"]+)" is "([^\"]+)"$/)
GivenStudyMetadata(:ega_dac_accession_number, /^the dac accession number for study "([^\"]+)" is "([^\"]+)"$/)
GivenStudyMetadata(:array_express_accession_number, /^the Array Express accession number for study "([^\"]+)" is "([^\"]+)"$/)
GivenStudyMetadata(:ega_policy_accession_number, /^the EGA policy accession number for study "([^\"]+)" is "([^\"]+)"$/)

Given /^the (abstract|description|title) of study "([^\"]+)" is "([^\"]*)"$/ do |attribute, name, description|
  study = Study.find_by(name: name) or raise StandardError, "There appears to be no study named '#{name}'"
  attribute = 'study_title' if attribute == 'title' # Got to love consistency
  study.study_metadata.send(:"study_#{ attribute }=", description)
  study.save!
end

Then /^the description of the study "([^\"]+)" should be "([^\"]+)"$/ do |name, description|
  study = Study.find_by(name: name) or raise StandardError, "There appears to be no study named '#{name}'"
  assert_equal(description, study.study_metadata.study_description)
end

Given /^the study "([^\"]+)" is delayed for (3|6|9|12) months because "([^\"]+)"$/ do |name, period, reason|
  study = Study.find_by(name: name) or raise StandardError, "There appears to be no study named '#{name}'"
  study.update_attributes!(
    study_metadata_attributes: {
      data_release_timing: 'delayed',
      data_release_delay_reason: 'other',
      data_release_delay_other_comment: reason,
      data_release_delay_period: "#{period} months",
      data_release_delay_approval: 'Yes',
      data_release_delay_reason_comment: reason
    }
  )
end

Given /^the study "([^\"]*)" has the following contacts$/ do |study, table|
  table.hashes.each do |hash|
    step 'user "' + hash['login'] + '" is a "' + hash['role'] + '" of study "' + study + '"'
  end
end

Given /^study "([^\"]*)" has asset and assetgroup$/ do |study|
  proj = Study.find_by(name: study)
  user = User.find_by login: 'user'

  id_asset_group = FactoryGirl.create :asset_group, name: 'new_asset_group', user: user, study: proj
  #  id_asset = FactoryGirl.create :asset, :name => 'Cucumberirbattle', :sti_type => 'SampleTube', :barcode => 'barcode', :sample_id => '1', :closed => '0'
  id_asset = FactoryGirl.create :sample_tube, name: 'Cucumberirbattle', barcode: 'barcode', closed: '0'
  id_aga = FactoryGirl.create :asset_group_asset, asset_id: id_asset.id, asset_group_id: id_asset_group.id
end

Given /^study "([^\"]*)" has asset and assetgroup called "([^\"]*)"$/ do |study, new_asset_group|
  proj = Study.find_by(name: study)
  user = User.find_by login: 'user'

  id_asset_group = FactoryGirl.create :asset_group, name: new_asset_group, user: user, study: proj
  id_asset = FactoryGirl.create :sample_tube, name: 'Cucumberirbattle', barcode: 'barcode', closed: '0'
  id_aga = FactoryGirl.create :asset_group_asset, asset_id: id_asset.id, asset_group_id: id_asset_group.id
end

Given /^study "([^\"]*)" has plate and assetgroup$/ do |study_name|
  study = Study.find_by(name: study_name)
  user = User.find_by login: 'user'

  id_asset_group = FactoryGirl.create :asset_group, name: 'new_asset_group', user: user, study: study
  sample = FactoryGirl.create :sample
  study.samples << sample
  map   = FactoryGirl.create :map
  plate = FactoryGirl.create :plate, name: 'Cucumberirbattle', barcode: '123', closed: '0'
  well = FactoryGirl.create :well, name: 'Well 1', closed: '0', sample: sample, map: map
  well.plate = plate
  well.save
  id_aga = FactoryGirl.create :asset_group_asset, asset_id: well.id, asset_group_id: id_asset_group.id
end

Given /^study "([^\"]*)" has an accession number$/ do |name|
  study = Study.find_by(name: name) or raise StandardError, "Cannot find study with name '#{name}'"
  study.study_metadata.study_ebi_accession_number = 9999
  study.study_metadata.data_release_strategy ||= 'managed'
  study.save!
end

Given /^study "([^\"]*)" DNA properties value$/ do |name|
  study = Study.find_by(name: name) or raise StandardError, "Cannot find study with name '#{name}'"
  study.study_metadata.contains_human_dna = Study::YES
  study.study_metadata.contaminated_human_dna = Study::NO
  study.save!
end

####################################################################################################################
# Used in features/listing_by_type
####################################################################################################################
Given /^studies will appear in the following study lists:$/ do |table|
  table.raw.each do |study_list|
    step(%Q{a study will appear in the study list "#{study_list}"})
  end
end

Given /^a study will appear in the study list "([^\"]+)"$/ do |study_list|
  FactoryGirl.create(:"study_for_study_list_#{ study_list.downcase.gsub(/[^a-z0-9]+/, '_') }")
end

Then /^I should see the studies for the following study lists:$/ do |table|
  table.raw.each do |study_list|
    step %Q{I should see the study for study list "#{study_list}"}
  end
end

Then /^I should see the study for study list "([^\"]+)"$/ do |study_list|
  step %Q{I should see "Study: #{study_list}"}
end

Given /^asset with barcode "([^"]*)" belongs to study "([^"]*)"$/ do |raw_barcode, study_name|
  asset = Asset.find_from_machine_barcode(raw_barcode) or raise StandardError, "Cannot find asset with machine barcode #{raw_barcode.inspect}"
  assign_asset_to_study(asset, study_name)
end

Given /^the asset "([^\"]+)" belongs to study "([^\"]+)"$/ do |asset_name, study_name|
  asset = Asset.find_by!(name: asset_name)
  assign_asset_to_study(asset, study_name)
end

def assign_asset_to_study(asset, study_name)
  study = Study.find_by!(name: study_name)

  asset_ids = if asset.respond_to?(:wells)
                asset.wells.pluck(:id)
              else
                [asset.id]
              end

  if asset.can_be_created? || (asset.respond_to?(:wells) && (asset.stock_plate?))
    RequestFactory.create_assets_requests(Asset.find(asset_ids), study)
  end
  Asset.where(id: asset_ids).includes(:aliquots).each do |asset|
    asset.aliquots.each do |aliquot|
      aliquot.update_attributes!(study_id: study.id)
    end
  end
end

Then /^abbreviation for Study "([^"]*)" should be "([^"]*)"$/ do |study_name, abbreviation_regex|
  study = Study.find_by(name: study_name)
  assert_not_nil study.abbreviation.match(Regexp.new(abbreviation_regex))
end
When /^I get the XML accession for the study *"([^\"]+)"$/ do |name|
  study = Study.find_by(name: name) or raise StandardError, "Cannot find sample with name #{name.inspect}"
  visit(url_for(controller: 'studies', action: 'show_accession', id: study.id, format: :xml))
end

Given /^the study "([^\"]+)" has a (library tube) called "([^\"]+)"$/ do |study_name, asset_model, asset_name|
  study = Study.find_by(name: study_name) or raise StandardError, "Cannot find study #{study_name.inspect}"
  asset = FactoryGirl.create(asset_model.gsub(/\s+/, '_').to_sym, name: asset_name)
  step %Q(the asset "#{asset_name}" belongs to study "#{study_name}")
end

Then /^the help text for "([^\"]*)" should contain:$/ do |label_name, expected_tooltip_text|
  link = find(:xpath, "//label[text()='#{label_name}']/../..//span[text()='?']")
  link.click
  step %Q{I should see "#{expected_tooltip_text}"}
end

Then /^I should exactly see "([^"]*)"$/ do |text|
  assert !find(:xpath, "//label[text()='#{text}']").text.blank?
end

When /^I generate an? (dac|policy|array express) accession number for study "([^\"]+)"$/ do |type, study_name|
 type = { 'dac' => 'DAC', 'policy' => 'Policy', 'array express' => '' }.fetch(type, type)
 step %Q{I am on the workflow page for study "#{study_name}"}
 step %Q{I follow "Generate #{type} Accession Number"}.gsub(/  +/, ' ')
end

When /^I generate an? accession number for study "([^\"]+)"$/ do |study_name|
 step %Q{I am on the workflow page for study "#{study_name}"}
 step('I follow "Generate Accession Number"')
end

When /^I update an? accession number for study "([^\"]+)"$/ do |study_name|
 step %Q{I am on the workflow page for study "#{study_name}"}
 step('I follow "Update EBI Study data"')
end

Given /^the study "([^\"]+)" has a valid policy$/ do |study_name|
    step(%Q{the policy for study "#{study_name}" is "http://www.example.com"})
    step(%Q{the dac accession number for study "#{study_name}" is "EGAC00000001"})
end

Given /^the study "([^\"]+)" has a valid dac$/ do |study_name|
  step('user "dac" exists')
  step(%Q{user "dac" is an "Data Access Contact" of study "#{study_name}"})
end

Given /^the study "([^\"]+)" is "([^\"]+)" of study "([^\"]+)"/ do |related_study_name, relation_name, study_name|
  study = Study.find_by(name: study_name) or raise StandardError, "Cannot find study #{study_name.inspect}"
  related_study = Study.find_by(name: related_study_name) or raise StandardError, "Cannot find related_study #{related_study_name.inspect}"
  StudyRelationType::relate_studies_by_name!(relation_name, study, related_study)
end

Given /^a study named "([^\"]+)" exists for accession/ do |study_name|
    step(%Q{a study named "#{study_name}" exists})
    step(%Q{an accession number is required for study "#{study_name}"})
    step %Q{the title of study "#{study_name}" is "Testing accession numbers"}
    step %Q{the description of study "#{study_name}" is "To find out if something is broken"}
    step %Q{the abstract of study "#{study_name}" is "Ok, not ok?"}
  step %Q{the study "#{study_name}" is a "Whole Genome Sequencing" study}
end
Given /^a study named "([^\"]+)" exists for array express/ do |study_name|
  step(%Q{a study named "#{study_name}" exists for accession})
  step %Q{the study "#{study_name}" is a "Whole Genome Sequencing" study}
end

Given /^study "([^"]*)" has a study title of "([^"]*)"$/ do |study_name, study_title|
  study = Study.find_by(name: study_name)
  study.study_metadata.update_attributes!(study_study_title: study_title)
end

Given /^study "([^"]*)" has an ENA project ID of "([^"]*)"$/ do |study_name, ena_project_id|
  study = Study.find_by(name: study_name)
  study.study_metadata.update_attributes!(study_project_id: ena_project_id)
end

Given /^I create study "([^"]*)" with faculty sponsor "([^"]*)"$/ do |study_name, faculty_sponsor|
  step('I am on the homepage')
  step('I follow "Create Study"')
  step(%Q{I fill in "Study name" with "#{study_name}"})
  step('I select "Not suitable for alignment" from "Reference genome"')
  step('I fill in "Data access group" with "some nonsense"')
  step('I fill in "Study description" with "some description"')
  step(%Q{I select "#{faculty_sponsor}" from "Faculty Sponsor"})
  step('I press "Create"')
end

Then /^the list of studies should be:$/ do |expected_results_table|
  expected_results_table.diff!(table(fetch_table('table#study_list')))
end

Then /^the faculty sponsor index page should look like:$/ do |expected_results_table|
  expected_results_table.diff!(table(fetch_table('table#faculty_sponsor_list')))
end

When /^I have an? (managed|open) study without a data release group called "(.*?)"$/ do |managed, study_name|
  Study.create!(
      name: study_name,
      study_metadata_attributes: {
        program: Program.find_by(name: 'General'),
        faculty_sponsor: FactoryGirl.create(:faculty_sponsor),
        study_type: StudyType.last,
        data_release_strategy: managed,
        study_description: 'blah',
        data_release_study_type: DataReleaseStudyType.first,
        contaminated_human_dna: 'No',
        contains_human_dna: 'Yes',
        commercially_available: 'No'
      }
    )
end

Given /^the study "(.*?)" has a data access group of "(.*?)"$/ do |study_name, dag|
  Study.find_by(name: study_name).study_metadata.update_attributes!(data_access_group: dag)
end
