# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2012,2013,2014,2015 Genome Research Ltd.

When /^I attach a valid excel file$/ do
  attach_file(:file, File.join(Rails.root, 'public', 'data', 'sample_information.xls'))
end

Then /^a "([^\"]*)" number of "([^\"]*)" should be created$/ do |num, records|
  assert_equal num.to_i, records.humanize.constantize.count
end

Then /^No records of "([^\"]*)" should be created$/ do |records|
  assert_equal [], records.humanize.constantize.count
end

Then /^I should see an error "([^\"]*)"$/ do |msg|
  assert_contain msg
end

Then /^the following samples should be in the sample registration fields:$/ do |table|
  number = table.rows.count
  approved_heads = table.headers
  heads = find('table#samples_to_register').find_all('thead th').map { |th| th.text }
  rows = find('table#samples_to_register').find_all("tbody tr:nth-child(-n+#{number})")
  hashes = rows.map do |tr|
    hash = Hash[heads.zip(tr.find_all('td').map { |td| td.first('input').try(:value) || td.first('select').try(:value) })]
    hash.slice(*approved_heads)
  end
  assert_equal table.hashes, hashes
end

Given /^the sample "([^\"]+)" has the Taxon ID "([^\"]+)"$/ do |name, id|
  sample = Sample.find_by(name: name) or raise StandardError, "Cannot find sample with name #{name.inspect}"
  sample.sample_metadata.sample_taxon_id = id
  sample.save!
end

Given /^the sample "([^\"]+)" has the common name "([^\"]*)"$/ do |name, common_name|
  sample = Sample.find_by(name: name) or raise StandardError, "Cannot find sample with name #{name.inspect}"
  sample.sample_metadata.sample_common_name = common_name
  sample.save!
end

Given /^the sample "([^\"]+)" has the gender "([^\"]*)"$/ do |name, gender|
  sample = Sample.find_by(name: name) or raise StandardError, "Cannot find sample with name #{name.inspect}"
  sample.sample_metadata.gender = gender
  sample.save!
end

Given /^the sample "([^\"]+)" has the donor id "([^\"]*)"$/ do |name, donor_id|
  sample = Sample.find_by(name: name) or raise StandardError, "Cannot find sample with name #{name.inspect}"
  sample.sample_metadata.donor_id = donor_id
  sample.save!
end

Given /^the sample "([^\"]+)" has the phenotype "([^\"]*)"$/ do |name, phenotype|
  sample = Sample.find_by(name: name) or raise StandardError, "Cannot find sample with name #{name.inspect}"
  sample.sample_metadata.phenotype = phenotype
  sample.save!
end

Given /^the sample "([^\"]+)" belongs to the study "([^\"]+)"$/ do |sample_name, study_name|
  sample = Sample.find_by(name: sample_name) or raise StandardError, "Cannot find sample with name #{sample_name.inspect}"
  study  = Study.find_by(name: study_name) or raise StandardError, "Cannot find study with name #{study_name.inspect}"
  study.samples << sample
end

Then /^the reference genome for the sample "([^\"]+)" should be "([^\"]+)"$/ do |name, genome|
  sample = Sample.find_by(name: name) or raise StandardError, "Cannot find sample with name #{name.inspect}"
  assert_equal(genome, sample.sample_metadata.reference_genome.name)
end

Then /^the UUID for the sample "([^\"]+)" should be "([^\"]+)"$/ do |name, uuid|
  sample = Sample.find_by(name: name) or raise StandardError, "Cannot find sample with name #{name.inspect}"
  assert_equal(uuid, sample.uuid)
end

Then /^the XML root attribute "([^\"]+)" sent to the accession service for sample "([^\"]+)" should be not present$/ do |xml_attr, sample_name|
  sample = Sample.find_by(name: sample_name) or raise StandardError, "Cannot find sample with name #{sample_name.inspect}"
  xml = FakeAccessionService.instance.sent.last['SAMPLE'].to_s
  assert_equal(true, Nokogiri(xml).xpath("/SAMPLE_SET/SAMPLE/@#{xml_attr}").length == 0)
end

Then /^the XML root attribute "([^\"]+)" sent to the accession service for sample "([^\"]+)" should be "(.*?)"$/ do |xml_attr, sample_name, value|
  sample = Sample.find_by(name: sample_name) or raise StandardError, "Cannot find sample with name #{sample_name.inspect}"
  xml = FakeAccessionService.instance.sent.last['SAMPLE'].to_s
  assert_equal(value, Nokogiri(xml).xpath("/SAMPLE_SET/SAMPLE/@#{xml_attr}").map(&:to_s)[0])
end

Then /^the XML sent for sample "([^\"]+)" validates with the schema "([^\"]+)"$/ do |sample_name, schema|
  sample = Sample.find_by(name: sample_name) or raise StandardError, "Cannot find sample with name #{sample_name.inspect}"
  xml = FakeAccessionService.instance.sent.last['SAMPLE'].to_s
  # Schema downloaded from http://www.ebi.ac.uk/ena/submit/data-formats
  xsd = Nokogiri::XML::Schema(File.open(schema))
  result = xsd.validate(Nokogiri(xml))
  assert(result.length == 0, result.map(&:message).join(''))
end

Then /^the XML identifier tag "([^\"]+)" sent to the accession service for sample "([^\"]+)" should be not present$/ do |xml_attr, sample_name|
  sample = Sample.find_by(name: sample_name) or raise StandardError, "Cannot find sample with name #{sample_name.inspect}"
  xml = FakeAccessionService.instance.sent.last['SAMPLE'].to_s
  assert_equal(true, Nokogiri(xml).xpath("/SAMPLE_SET/SAMPLE/IDENTIFIERS/#{xml_attr}").length == 0)
end

Then /^the XML tag "([^\"]+)" sent to the accession service for sample "([^\"]+)" should be not present$/ do |xml_attr, sample_name|
  sample = Sample.find_by(name: sample_name) or raise StandardError, "Cannot find sample with name #{sample_name.inspect}"
  xml = FakeAccessionService.instance.sent.last['SAMPLE'].to_s
  assert_equal(true, Nokogiri(xml).xpath("/SAMPLE_SET/SAMPLE/#{xml_attr}").length == 0)
end

Then /^the XML identifier tag "([^\"]+)" sent to the accession service for sample "([^\"]+)" should be "(.*?)"$/ do |xml_attr, sample_name, value|
  sample = Sample.find_by(name: sample_name) or raise StandardError, "Cannot find sample with name #{sample_name.inspect}"
  xml = FakeAccessionService.instance.sent.last['SAMPLE'].to_s
  assert_equal(value, Nokogiri(xml).xpath("/SAMPLE_SET/SAMPLE/IDENTIFIERS/#{xml_attr}").text)
end

Then /^the XML tag "([^\"]+)" sent to the accession service for sample "([^\"]+)" should be "(.*?)"$/ do |xml_attr, sample_name, value|
  sample = Sample.find_by(name: sample_name) or raise StandardError, "Cannot find sample with name #{sample_name.inspect}"
  xml = FakeAccessionService.instance.sent.last['SAMPLE'].to_s
  assert_equal(value, Nokogiri(xml).xpath("/SAMPLE_SET/SAMPLE/#{xml_attr}").text)
end

Given /^the metadata attribute "(.*?)" of the sample "(.*?)" is "(.*?)"$/ do |attr_name, sample_name, value|
  sample = Sample.find_by(name: sample_name) or raise StandardError, "Cannot find sample with name #{sample_name.inspect}"
  sample.sample_metadata.update_attributes(Hash[attr_name, (value unless value == 'empty')])
end

Given /^the attribute "(.*?)" of the sample "(.*?)" is "(.*?)"$/ do |attr_name, sample_name, value|
  sample = Sample.find_by(name: sample_name) or raise StandardError, "Cannot find sample with name #{sample_name.inspect}"
  sample.update_attributes(Hash[attr_name, (value unless value == 'empty')])
end

Then /^the sample "([^\"]+)" should exist$/ do |name|
  assert_not_nil(Sample.find_by(name: name), "The sample #{name.inspect} does not exist")
end

Then /^the sample "([^\"]+)" should have an associated sample tube$/ do |name|
  sample = Sample.find_by(name: name) or raise StandardError, "Cannot find sample with name #{name.inspect}"
  assert(!sample.assets.empty?, 'No associated sample tubes')
end

When /^I get the XML for the sample "([^\"]+)"$/ do |name|
  sample = Sample.find_by(name: name) or raise StandardError, "Cannot find sample with name #{name.inspect}"
  visit(url_for(controller: 'samples', action: 'show', id: sample, format: :xml))
end

Given /^I have a sample called "([^"]*)" with metadata$/ do |name|
  sample = FactoryGirl.create :sample, name: name
end

Given /^the sample "([^"]*)" has a supplier name of "([^"]*)"$/ do |sample_name, supplier_name|
  sample = Sample.find_by(name: sample_name)
  sample.sample_metadata.update_attributes!(supplier_name: supplier_name)
end

Given /^the sample "([^\"]+)" is in the (sample tube|well) "([^\"]+)"$/ do |sample_name, _asset_type, asset_name|
  sample = Sample.find_by(name: sample_name) or raise StandardError, "Cannot find sample #{sample_name.inspect}"
  asset = Asset.find_by(name: asset_name) or raise StandardError, "Cannot find sample tube #{asset_name.inspect}"
  asset.aliquots.clear
  asset.aliquots.create!(sample: sample)
end

Then /^sample "([^"]*)" should have an accession number of "([^"]*)"$/ do |sample_name, accession_number|
  sample = Sample.find_by(name: sample_name) or raise StandardError, "Cannot find sample #{sample_name.inspect}"
  assert_equal accession_number, sample.sample_metadata.sample_ebi_accession_number
end

Then /^sample "([^"]*)" should not have an accession number of "([^"]*)"$/ do |sample_name, accession_number|
  sample = Sample.find_by(name: sample_name) or raise StandardError, "Cannot find sample #{sample_name.inspect}"
  assert accession_number != sample.sample_metadata.sample_ebi_accession_number
end

Given /^the sample "([^"]*)" should not have an accession number$/ do |sample_name|
  sample = Sample.find_by(name: sample_name) or raise StandardError, "Cannot find sample #{sample_name.inspect}"
  assert_nil sample.sample_metadata.sample_ebi_accession_number
end

Given(/^the sample "([^\"]+)" has the accession number "([^\"]+)"$/) do |name, value|
  sample = Sample.find_by!(name: name)
  sample.sample_metadata.sample_ebi_accession_number = value.blank? ? nil : value
  sample.save!
end

When /^I (create|update) an? accession number for sample "([^\"]+)"$/ do |action_type, sample_name|
  step %Q{I am on the show page for sample "#{sample_name}"}
  action_str = (action_type == 'create') ? 'Generate Accession Number' : 'Update EBI Sample data'
  step(%Q{I follow "#{action_str}"})
end

Then /^I (should|should not) have (sent|received) the attribute "([^\"]*)" for the sample element (to|from) the accessioning service$/ do |state_action, type_action, attr_name, _dest|
  xml = (type_action == 'sent') ? FakeAccessionService.instance.sent.last['SAMPLE'] : FakeAccessionService.instance.last_received
  assert_equal (state_action == 'should'), Nokogiri(xml).xpath("/SAMPLE_SET/SAMPLE/@#{attr_name}").map(&:to_s).present?, "XML was: #{xml}"
end

Given /^sample "([^"]*)" came from a sample manifest$/ do |sample_name|
  sample = Sample.find_by(name: sample_name)
  sample_manifest = FactoryGirl.create(:sample_manifest, id: 1)
  sample.update_attributes!(sample_manifest: sample_manifest)
end

Given /^study "([^\"]+)" has the following samples in sample tubes:$/ do |study_name, table|
  study = Study.find_by(name: study_name) or raise StandardError, "Cannot find study #{study_name.inspect}"
  table.hashes.each do |details|
    sample_tube_name = details['sample tube']
    sample_name = details['sample']

    sample = Sample.find_by(name: sample_name)
    step %Q{I have a sample called "#{sample_name}"} unless sample
    step(%Q{sample "#{sample_name}" is in a sample tube named "#{sample_tube_name}"})
    step(%Q{the sample "#{sample_name}" belongs to the study "#{study_name}"})
    step(%Q{the asset "#{sample_tube_name}" belongs to study "#{study_name}"})
  end
end

Then /^the sample "([^"]*)" should belong to the study named "([^"]*)"$/ do |sample_name, study_name|
  sample = Sample.find_by(name: sample_name) or raise StandardError, "Cannot find sample #{sample_name.inspect}"
  study  = Study.find_by(name: study_name) or raise StandardError, "Cannot find study #{study_name.inspect}"
  assert study.samples.include?(sample)
end
Then /^the sample "([^"]*)" should not belong to the study named "([^"]*)"$/ do |sample_name, study_name|
  sample = Sample.find_by(name: sample_name) or raise StandardError, "Cannot find sample #{sample_name.inspect}"
  study  = Study.find_by(name: study_name) or raise StandardError, "Cannot find study #{study_name.inspect}"
  assert !study.samples.include?(sample)
end

Given /^a sample named "([^\"]+)" exists for accession/ do |sample_name|
  study_name = "study for sample #{sample_name}"
  step(%Q{a study named "#{study_name}" exists for accession})
  step(%Q{the sample named "#{sample_name}" exists with ID 200})
  step(%Q{study "#{study_name}" has an accession number})
  step('I am the owner of sample "sample"')
  step(%Q{the sample "#{sample_name}" belongs to the study "#{study_name}"})
  step(%Q{the sample "#{sample_name}" has the Taxon ID "99999"})
  step(%Q{the sample "#{sample_name}" has the common name "Human"})
end

Given /^the Sanger sample ID of the last sample is "([^\"]+)"$/ do |id|
  sample = Sample.last or raise StandardError, 'There appear to be no samples'
  sample.update_attributes!(sanger_sample_id: id)
end

Given /^all samples have a Sanger sample ID based on "([^\"]+)"$/ do |id|
  Sample.all.each_with_index do |sample, index|
    sample.update_attributes!(sanger_sample_id: "#{id}#{'%02d' % (index + 1)}")
  end
end

Given /^the supplier sample name of the last sample is "([^\"]+)"$/ do |name|
  sample = Sample.last or raise StandardError, 'There appear to be no samples'
  sample.update_attributes!(sample_metadata_attributes: { supplier_name: name })
end

Given /^the sample called "([^\"]+)" is (#{SampleMetadata::GENDERS.join('|')})$/ do |name, gender|
  sample = Sample.find_by(name: name) or raise StandardError, "Cannot find the sample #{name.inspect}"
  sample.update_attributes!(sample_metadata_attributes: { gender: gender })
end

Given /^the GC content of the sample called "([^\"]+)" is (#{SampleMetadata::GC_CONTENTS.join('|')})$/ do |name, gc_content|
  sample = Sample.find_by(name: name) or raise StandardError, "Cannot find the sample #{name.inspect}"
  sample.update_attributes!(sample_metadata_attributes: { gc_content: gc_content })
end

Given /^the DNA source of the sample called "([^\"]+)" is (#{SampleMetadata::DNA_SOURCES.join('|')})$/ do |name, source|
  sample = Sample.find_by(name: name) or raise StandardError, "Cannot find the sample #{name.inspect}"
  sample.update_attributes!(sample_metadata_attributes: { dna_source: source })
end

Given /^the SRA status of the sample called "([^\"]+)" is (#{SampleMetadata::SRA_HOLD_VALUES.join('|')})$/ do |name, sra_status|
  sample = Sample.find_by(name: name) or raise StandardError, "Cannot find the sample #{name.inspect}"
  sample.update_attributes!(sample_metadata_attributes: { sample_sra_hold: sra_status })
end

Given /^the sample called "([^\"]+)" is (#{SampleMetadata::AGE_REGEXP}) old$/ do |name, age|
  sample = Sample.find_by(name: name) or raise StandardError, "Cannot find the sample #{name.inspect}"
  sample.update_attributes!(sample_metadata_attributes: { age: age })
end

Given /^the dosage of the sample called "([^\"]+)" is (#{SampleMetadata::DOSE_REGEXP})/ do |name, dose|
  sample = Sample.find_by(name: name) or raise StandardError, "Cannot find the sample #{name.inspect}"
  sample.update_attributes!(sample_metadata_attributes: { dose: dose })
end

Given /^the description of the sample called "([^\"]+)" contains quotes/ do |name|
  sample = Sample.find_by(name: name) or raise StandardError, "Cannot find the sample #{name.inspect}"
  sample.update_attributes!(sample_metadata_attributes: { sample_description: 'something "with" quotes' })
end

Given /^there are no samples$/ do
  # Imagine there's no samples,
  # it's easy if you try
  # To bypass all the callbacks
  # That trigger when they die
  Sample.delete_all
  Uuid.where(resource_type: 'Sample').each(&:destroy)
end

Given /^the sample "(.*?)" should have an accesionable flag$/ do |name|
  sample = Sample.find_by(name: name) or raise StandardError, "Cannot find the sample #{name.inspect}"
  assert sample.accession_could_be_generated?
end

Given /^the sample "(.*?)" should not have an accesionable flag$/ do |name|
  sample = Sample.find_by(name: name) or raise StandardError, "Cannot find the sample #{name.inspect}"
  assert !sample.accession_could_be_generated?
end
