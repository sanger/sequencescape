# frozen_string_literal: true

Given /^the sample "([^"]+)" has the Taxon ID "([^"]+)"$/ do |name, id|
  sample = Sample.find_by(name:) or raise StandardError, "Cannot find sample with name #{name.inspect}"
  sample.sample_metadata.sample_taxon_id = id
  sample.save!
end

Given /^the sample "([^"]+)" has the common name "([^"]*)"$/ do |name, common_name|
  sample = Sample.find_by(name:) or raise StandardError, "Cannot find sample with name #{name.inspect}"
  sample.sample_metadata.sample_common_name = common_name
  sample.save!
end

Given /^the sample "([^"]+)" has the gender "([^"]*)"$/ do |name, gender|
  sample = Sample.find_by(name:) or raise StandardError, "Cannot find sample with name #{name.inspect}"
  sample.sample_metadata.gender = gender
  sample.save!
end

Given /^the sample "([^"]+)" has the donor id "([^"]*)"$/ do |name, donor_id|
  sample = Sample.find_by(name:) or raise StandardError, "Cannot find sample with name #{name.inspect}"
  sample.sample_metadata.donor_id = donor_id
  sample.save!
end

Given /^the sample "([^"]+)" has the phenotype "([^"]*)"$/ do |name, phenotype|
  sample = Sample.find_by(name:) or raise StandardError, "Cannot find sample with name #{name.inspect}"
  sample.sample_metadata.phenotype = phenotype
  sample.save!
end

Given /^the reference genome for sample "([^"]+)" is "([^"]+)"$/ do |name, value|
  sample = Sample.find_by!(name:)
  ref_genome = ReferenceGenome.find_or_create_by!(name: value)
  sample.sample_metadata.reference_genome = ref_genome
  sample.save!
end

Given /^the sample "([^"]+)" belongs to the study "([^"]+)"$/ do |sample_name, study_name|
  sample = Sample.find_by(name: sample_name) or
    raise StandardError, "Cannot find sample with name #{sample_name.inspect}"
  study = Study.find_by(name: study_name) or raise StandardError, "Cannot find study with name #{study_name.inspect}"
  study.samples << sample
end

Then /^the reference genome for the sample "([^"]+)" should be "([^"]+)"$/ do |name, genome|
  sample = Sample.find_by(name:) or raise StandardError, "Cannot find sample with name #{name.inspect}"
  assert_equal(genome, sample.sample_metadata.reference_genome.name)
end

Given /^the metadata attribute "(.*?)" of the sample "(.*?)" is "(.*?)"$/ do |attr_name, sample_name, value|
  sample = Sample.find_by(name: sample_name) or
    raise StandardError, "Cannot find sample with name #{sample_name.inspect}"
  sample.sample_metadata.update({ attr_name => (value unless value == 'empty') })
end

Given /^the attribute "(.*?)" of the sample "(.*?)" is "(.*?)"$/ do |attr_name, sample_name, value|
  sample = Sample.find_by(name: sample_name) or
    raise StandardError, "Cannot find sample with name #{sample_name.inspect}"
  sample.update({ attr_name => (value unless value == 'empty') })
end

Then /^the sample "([^"]+)" should exist$/ do |name|
  assert_not_nil(Sample.find_by(name:), "The sample #{name.inspect} does not exist")
end

Then /^the sample "([^"]+)" should have an associated sample tube$/ do |name|
  sample = Sample.find_by(name:) or raise StandardError, "Cannot find sample with name #{name.inspect}"
  assert(!sample.assets.empty?, 'No associated sample tubes')
end

When /^I get the XML for the sample "([^"]+)"$/ do |name|
  sample = Sample.find_by(name:) or raise StandardError, "Cannot find sample with name #{name.inspect}"
  visit(url_for(controller: 'samples', action: 'show', id: sample, format: :xml))
end

Given /^I have a sample called "([^"]*)" with metadata$/ do |name|
  sample = FactoryBot.create :sample, name:
end

Given /^the sample "([^"]*)" has a supplier name of "([^"]*)"$/ do |sample_name, supplier_name|
  sample = Sample.find_by(name: sample_name)
  sample.sample_metadata.update!(supplier_name:)
end

Given /^the sample "([^"]+)" is in the (sample tube|well) "([^"]+)"$/ do |sample_name, _asset_type, asset_name|
  sample = Sample.find_by(name: sample_name) or raise StandardError, "Cannot find sample #{sample_name.inspect}"
  asset = Labware.find_by(name: asset_name).receptacle or
    raise StandardError, "Cannot find sample tube #{asset_name.inspect}"
  asset.aliquots.clear
  asset.aliquots.create!(sample:)
end

Given(/^the sample "([^"]+)" has the accession number "([^"]+)"$/) do |name, value|
  sample = Sample.find_by!(name:)
  sample.sample_metadata.sample_ebi_accession_number = value.presence
  sample.save!
end

When /^I (create|update) an? accession number for sample "([^"]+)"$/ do |action_type, sample_name|
  step "I am on the show page for sample \"#{sample_name}\""
  action_str = action_type == 'create' ? 'Generate Accession Number' : 'Update Sample Data for Accessioning'
  step("I follow \"#{action_str}\"")
end

Given /^sample "([^"]*)" came from a sample manifest$/ do |sample_name|
  sample = Sample.find_by(name: sample_name)
  sample_manifest = FactoryBot.create(:sample_manifest, id: 1)
  sample.update!(sample_manifest:)
end

Given /^a sample named "([^"]+)" exists for accession/ do |sample_name|
  study_name = "study for sample #{sample_name}"
  step("a study named \"#{study_name}\" exists for accession")
  step("the sample named \"#{sample_name}\" exists with ID 200")
  step("study \"#{study_name}\" has an accession number")
  step('I am the owner of sample "sample"')
  step("the sample \"#{sample_name}\" belongs to the study \"#{study_name}\"")
  step("the sample \"#{sample_name}\" has the Taxon ID \"99999\"")
  step("the sample \"#{sample_name}\" has the common name \"Human\"")
end

Given /^the Sanger sample ID of the last sample is "([^"]+)"$/ do |id|
  sample = Sample.last or raise StandardError, 'There appear to be no samples'
  sample.update!(sanger_sample_id: id)
end

Given /^all samples have a Sanger sample ID based on "([^"]+)"$/ do |id|
  Sample.all.each_with_index { |sample, index| sample.update!(sanger_sample_id: "#{id}#{'%02d' % (index + 1)}") }
end

Given /^the supplier sample name of the last sample is "([^"]+)"$/ do |name|
  sample = Sample.last or raise StandardError, 'There appear to be no samples'
  sample.update!(sample_metadata_attributes: { supplier_name: name })
end

Given /^the sample called "([^"]+)" is (#{Sample::GENDERS.join('|')})$/ do |name, gender|
  sample = Sample.find_by(name:) or raise StandardError, "Cannot find the sample #{name.inspect}"
  sample.update!(sample_metadata_attributes: { gender: })
end

Given /^the GC content of the sample called "([^"]+)" is (#{Sample::GC_CONTENTS.join('|')})$/ do |name, gc_content|
  sample = Sample.find_by(name:) or raise StandardError, "Cannot find the sample #{name.inspect}"
  sample.update!(sample_metadata_attributes: { gc_content: })
end

Given /^the DNA source of the sample called "([^"]+)" is (#{Sample::DNA_SOURCES.join('|')})$/ do |name, source|
  sample = Sample.find_by(name:) or raise StandardError, "Cannot find the sample #{name.inspect}"
  sample.update!(sample_metadata_attributes: { dna_source: source })
end

Given /^the SRA status of the sample called "([^"]+)" is (#{Sample::SRA_HOLD_VALUES.join('|')})$/ do |name, sra_status|
  sample = Sample.find_by(name:) or raise StandardError, "Cannot find the sample #{name.inspect}"
  sample.update!(sample_metadata_attributes: { sample_sra_hold: sra_status })
end

Given /^the sample called "([^"]+)" is (#{Sample::AGE_REGEXP}) old$/o do |name, age|
  sample = Sample.find_by(name:) or raise StandardError, "Cannot find the sample #{name.inspect}"
  sample.update!(sample_metadata_attributes: { age: })
end

Given /^the dosage of the sample called "([^"]+)" is (#{Sample::DOSE_REGEXP})/o do |name, dose|
  sample = Sample.find_by(name:) or raise StandardError, "Cannot find the sample #{name.inspect}"
  sample.update!(sample_metadata_attributes: { dose: })
end

Given /^the description of the sample called "([^"]+)" contains quotes/ do |name|
  sample = Sample.find_by(name:) or raise StandardError, "Cannot find the sample #{name.inspect}"
  sample.update!(sample_metadata_attributes: { sample_description: 'something "with" quotes' })
end

Given /^there are no samples$/ do
  # Imagine there's no samples,
  # it's easy if you try
  # To bypass all the callbacks
  # That trigger when they die
  Sample.delete_all
  Uuid.where(resource_type: 'Sample').find_each(&:destroy)
end
