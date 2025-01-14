# frozen_string_literal: true

Given /^I have a study called "([^"]*)"$/ do |study|
  FactoryBot.create :study, name: study, state: 'pending'
end

Given /^a study "(.*?)" is pending$/ do |study|
  Study.find_by(name: study).reset!
end

Given /^study "([^"]*)" status is "([^"]*)"$/ do |study, status|
  proj = Study.find_by(name: study)
  status == 'active' ? proj.activate! : proj.deactivate!
  proj.save
end

Given /^I have an "([^"]*)" study called "([^"]*)"$/ do |status, study|
  step "I have a study called \"#{study}\""
  step "study \"#{study}\" status is \"#{status}\""
end

Given /^study "([^"]*)" has assets registered$/ do |study|
  proj = Study.find_by(name: study)
  user = User.find_by login: 'user'
  new_sample_group = FactoryBot.create :asset_group, name: 'new_asset_group', user: user, study: proj
end

Given /^the following user records$/ do |table|
  table.hashes.each do |hash|
    User.create_with(FactoryBot.attributes_for(:user, hash)).find_or_create_by(login: hash['login'])
  end
end

Given /^user "([^"]*)" is an? "([^"]*)" of study "([^"]*)"$/ do |login, role_name, study|
  proj = Study.find_by(name: study)
  role = Role.find_by(name: role_name, authorizable_type: 'Study', authorizable_id: proj.id)
  if role.nil?
    role =
      FactoryBot.create :role,
                        name: role_name,
                        authorizable_type: 'Study',
                        authorizable_id: proj.id,
                        created_at: Time.zone.now,
                        updated_at: Time.zone.now
  end
  usr = User.find_by(login:)
  usr.roles << role
  usr.save
end

Given /^I have an active study called "([^"]*)"$/ do |study_name|
  step "I have a study called \"#{study_name}\""
  step "study \"#{study_name}\" status is \"active\""
end

Given /^I am visiting study "([^"]*)" homepage$/ do |study_name|
  study = Study.find_by(name: study_name)
  visit study_information_path(study)
end

And /^the study have a workflow$/ do
  # Do nothing
end

def given_fixed_study_metadata(attribute, value, regexp)
  Given(regexp) do |name|
    study = Study.find_by(name:) or raise StandardError, "There appears to be no study named '#{name}'"
    study.study_metadata.send(:"#{attribute}=", value)
    study.save!
  end
end

given_fixed_study_metadata(
  :contaminated_human_dna,
  Study::YES,
  /^the study "([^"]+)" has samples contaminated with human DNA$/
)
given_fixed_study_metadata(
  :remove_x_and_autosomes,
  Study::YES,
  /^the study "([^"]+)" has samples which need x and autosome data removed$/
)
given_fixed_study_metadata(:contains_human_dna, Study::YES, /^the study "([^"]+)" contains human DNA$/)
given_fixed_study_metadata(
  :commercially_available,
  Study::YES,
  /^the study "([^"]+)" contains samples commercially available$/
)
given_fixed_study_metadata(
  :commercially_available,
  Study::NO,
  /^the study "([^"]+)" does not contain samples commercially available$/
)

def given_study_metadata(attribute, regexp)
  Given(regexp) do |name, value|
    study = Study.find_by(name:) or raise StandardError, "There appears to be no study named '#{name}'"
    study.study_metadata.send(:"#{attribute}=", value.presence)
    study.save!
  end
end

given_study_metadata(:data_release_strategy, /^the study "([^"]+)" has an? (open|managed) data release strategy$/)
given_study_metadata(:data_release_timing, /^the study "([^"]+)" data release timing is (standard)$/)
given_study_metadata(:study_ebi_accession_number, /^the study "([^"]+)" has the accession number "([^"]+)"$/)

Given /^the study "([^"]+)" belongs to the program "([^"]*)"$/ do |study_name, program_name|
  study = Study.find_by(name: study_name) or raise StandardError, "There appears to be no study named '#{study_name}'"
  program = Program.find_by(name: program_name) or raise StandardError, "Program not valid: '#{program_name}'"
  study.study_metadata.program = program
  study.save!
end

Given(/^the study "([^"]+)" is a "([^"]*)" study$/) do |name, value|
  study = Study.find_by!(name:)
  study_type = StudyType.find_by!(name: value)
  study.study_metadata.study_type = study_type
  study.save!
end

Given(/^the study "([^"]+)" is a "([^"]+)" study for data release$/) do |name, value|
  study = Study.find_by!(name:)
  study_type_dr = DataReleaseStudyType.find_by!(name: value)
  study.study_metadata.data_release_study_type = study_type_dr
  study.save!
end

Given(/^the faculty sponsor for study "([^"]+)" is "([^"]+)"$/) do |name, value|
  study = Study.find_by!(name:)
  faculty_sponsor = FacultySponsor.create!(name: value)
  study.study_metadata.faculty_sponsor = faculty_sponsor
  study.save!
end

Given(/^the reference genome for study "([^"]+)" is "([^"]+)"$/) do |name, value|
  study = Study.find_by!(name:)
  ref_genome = ReferenceGenome.find_or_create_by!(name: value)
  study.study_metadata.reference_genome = ref_genome
  study.save!
end

given_study_metadata(:dac_policy, /^the policy for study "([^"]+)" is "([^"]+)"$/)
given_study_metadata(:ega_dac_accession_number, /^the dac accession number for study "([^"]+)" is "([^"]+)"$/)
given_study_metadata(
  :array_express_accession_number,
  /^the Array Express accession number for study "([^"]+)" is "([^"]+)"$/
)
given_study_metadata(:ega_policy_accession_number, /^the EGA policy accession number for study "([^"]+)" is "([^"]+)"$/)

Given /^the (abstract|description|title) of study "([^"]+)" is "([^"]*)"$/ do |attribute, name, description|
  study = Study.find_by(name:) or raise StandardError, "There appears to be no study named '#{name}'"
  attribute = 'study_title' if attribute == 'title' # Got to love consistency
  study.study_metadata.send(:"study_#{attribute}=", description)
  study.save!
end

Given /^the study "([^"]+)" is delayed for (3|6|9|12) months because "([^"]+)"$/ do |name, period, reason|
  study = Study.find_by(name:) or raise StandardError, "There appears to be no study named '#{name}'"
  study.update!(
    study_metadata_attributes: {
      data_release_timing: 'delayed',
      data_release_delay_reason: 'Other (please specify below)',
      data_release_delay_other_comment: reason,
      data_release_delay_period: "#{period} months"
    }
  )
end

Given /^the study "([^"]*)" has the following contacts$/ do |study, table|
  table.hashes.each { |hash| step 'user "' + hash['login'] + '" is a "' + hash['role'] + '" of study "' + study + '"' }
end

Given /^study "([^"]*)" has asset and assetgroup$/ do |study|
  proj = Study.find_by(name: study)
  user = User.find_by login: 'user'

  id_asset_group = FactoryBot.create :asset_group, user: user, study: proj
  id_asset = FactoryBot.create :sample_tube, name: 'Cucumberirbattle', barcode: 'barcode', closed: '0'
  id_aga = FactoryBot.create :asset_group_asset, asset_id: id_asset.id, asset_group_id: id_asset_group.id
end

Given /^study "([^"]*)" has an accession number$/ do |name|
  study = Study.find_by(name:) or raise StandardError, "Cannot find study with name '#{name}'"
  study.study_metadata.study_ebi_accession_number = 9999
  study.study_metadata.data_release_strategy ||= 'managed'
  study.save!
end

Given /^a study will appear in the study list "([^"]+)"$/ do |study_list|
  FactoryBot.create(
    :"study_for_study_list_#{study_list.downcase.gsub(/[^a-z0-9]+/, '_')}",
    user: User.find_by(login: 'listing_studies_user')
  )
end

Then /^I should see the study for study list "([^"]+)"$/ do |study_list|
  step "I should see \"Study: #{study_list}\""
end

Given /^asset with barcode "([^"]*)" belongs to study "([^"]*)"$/ do |raw_barcode, study_name|
  asset = Asset.find_from_barcode(raw_barcode) or
    raise StandardError, "Cannot find asset with machine barcode #{raw_barcode.inspect}"
  assign_asset_to_study(asset, study_name)
end

Given /^the asset "([^"]+)" belongs to study "([^"]+)"$/ do |asset_name, study_name|
  asset = Asset.find_by!(name: asset_name)
  assign_asset_to_study(asset, study_name)
end

def assign_asset_to_study(asset, study_name)
  study = Study.find_by!(name: study_name)

  asset_ids = asset.respond_to?(:wells) ? asset.wells.pluck(:id) : [asset.id]

  RequestFactory.create_assets_requests(Asset.find(asset_ids), study)

  Asset
    .where(id: asset_ids)
    .includes(:aliquots)
    .find_each { |asset| asset.aliquots.each { |aliquot| aliquot.update!(study_id: study.id) } }
end

Then /^abbreviation for Study "([^"]*)" should be "([^"]*)"$/ do |study_name, abbreviation_regex|
  study = Study.find_by(name: study_name)
  assert_not_nil study.abbreviation.match(Regexp.new(abbreviation_regex))
end
When /^I get the XML accession for the study *"([^"]+)"$/ do |name|
  study = Study.find_by(name:) or raise StandardError, "Cannot find sample with name #{name.inspect}"
  visit(url_for(controller: 'studies', action: 'show_accession', id: study.id, format: :xml))
end

Given /^the study "([^"]+)" has a (library tube) called "([^"]+)"$/ do |study_name, asset_model, asset_name|
  study = Study.find_by(name: study_name) or raise StandardError, "Cannot find study #{study_name.inspect}"
  asset = FactoryBot.create(asset_model.gsub(/\s+/, '_').to_sym, name: asset_name)
  step "the asset \"#{asset_name}\" belongs to study \"#{study_name}\""
end

Then /^the help text for "([^"]*)" should contain:$/ do |label_name, expected_tooltip_text|
  find(:xpath, "//label[text()='#{label_name}']/../..//small").assert_text(expected_tooltip_text)
end

Then /^I should exactly see "([^"]*)"$/ do |text|
  assert find(:xpath, "//label[text()='#{text}']").text.present?
end

When /^I generate an? (dac|policy|array express) accession number for study "([^"]+)"$/ do |type, study_name|
  type = { 'dac' => 'DAC', 'policy' => 'Policy', 'array express' => '' }.fetch(type, type)
  step "I am on the information page for study \"#{study_name}\""
  step "I follow \"Generate #{type} Accession Number\"".gsub(%r{  +}, ' ')
end

When /^I generate an? accession number for study "([^"]+)"$/ do |study_name|
  step "I am on the information page for study \"#{study_name}\""
  step('I follow "Generate Accession Number"')
end

When /^I update an? accession number for study "([^"]+)"$/ do |study_name|
  step "I am on the information page for study \"#{study_name}\""
  step('I follow "Update EBI Study data"')
end

Given /^the study "([^"]+)" has a valid policy$/ do |study_name|
  step("the policy for study \"#{study_name}\" is \"http://www.example.com\"")
  step("the dac accession number for study \"#{study_name}\" is \"EGAC00000001\"")
end

Given /^the study "([^"]+)" has a valid dac$/ do |study_name|
  step('user "dac" exists')
  step("user \"dac\" is an \"Data Access Contact\" of study \"#{study_name}\"")
end

Given /^a study named "([^"]+)" exists for accession/ do |study_name|
  step("a study named \"#{study_name}\" exists")
  step("an accession number is required for study \"#{study_name}\"")
  step "the title of study \"#{study_name}\" is \"Testing accession numbers\""
  step "the description of study \"#{study_name}\" is \"To find out if something is broken\""
  step "the abstract of study \"#{study_name}\" is \"Ok, not ok?\""
  step "the study \"#{study_name}\" is a \"Whole Genome Sequencing\" study"
end
Given /^a study named "([^"]+)" exists for array express/ do |study_name|
  step("a study named \"#{study_name}\" exists for accession")
  step "the study \"#{study_name}\" is a \"Whole Genome Sequencing\" study"
end

Given /^I create study "([^"]*)" with faculty sponsor "([^"]*)"$/ do |study_name, faculty_sponsor|
  step('I am on the homepage')
  step('I follow "Create Study"')
  step("I fill in \"Study name\" with \"#{study_name}\"")
  step('I select "Not suitable for alignment" from "Reference genome"')
  step('I fill in "Data access group" with "some nonsense"')
  step('I fill in "Study description" with "some description"')
  step("I select \"#{faculty_sponsor}\" from \"Faculty Sponsor\"")
  step('I choose "Yes" from "Do any of the samples in this study contain human DNA?"')
  step(
    # rubocop:todo Layout/LineLength
    'I choose "No" from "Does this study contain samples that are contaminated with human DNA which must be removed prior to analysis?"'
    # rubocop:enable Layout/LineLength
  )
  step(
    # rubocop:todo Layout/LineLength
    'I choose "Yes" from "Are all the samples to be used in this study commercially available, unlinked anonymised cell-lines?"'
    # rubocop:enable Layout/LineLength
  )
  step('I choose "Open (ENA)" from "What is the data release strategy for this study?"')
  step('I press "Create"')
end

Then /^the list of studies should be:$/ do |expected_results_table|
  expected_results_table.diff!(table(fetch_table('table#study_list')))
end

Then /^the faculty sponsor index page should look like:$/ do |expected_results_table|
  expected_results_table.diff!(table(fetch_table('table#faculty_sponsor_list')))
end

Then /^the faculty sponsor index page should include:$/ do |expected_results_table|
  # This version of `diff!` doesn't see additional rows in the 'actual table' as an issue
  # Necessary because our Record Loader adds extra data that the original Cucumber test doesn't expect
  expected_results_table.diff!(table(fetch_table('table#faculty_sponsor_list')), surplus_row: false)
end

When /^I have an? (managed|open) study without a data release group called "(.*?)"$/ do |managed, study_name|
  Study.create!(
    name: study_name,
    study_metadata_attributes: {
      program: Program.find_by(name: 'General'),
      faculty_sponsor: FactoryBot.create(:faculty_sponsor),
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
  Study.find_by(name: study_name).study_metadata.update!(data_access_group: dag)
end
