def GivenSampleMetadata(attribute, regexp)
  Given(regexp) do |name,value|
    sample = Sample.find_by_name(name) or raise StandardError, "There appears to be no sample named '#{ name }'"
    sample.sample_metadata.send(:"#{ attribute }=", value.blank? ? nil : value)
    sample.save!
  end
end


When /^I attach a valid excel file$/ do
  attach_file(:file, File.join(RAILS_ROOT, 'public', 'data', 'sample_information.xls'))
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

# TODO[xxx]: This is incredibly slow!
Then /^the following samples should be in the sample registration fields:$/ do |table|
  table.hashes.each_with_index do |details,index|
    with_scope("table#samples_to_register tr.sample_row:nth-child(#{index+1})") do
      details.each do |label, value|
        field       = find_field("#{ label } for sample #{ index }")
        field_value = (field.tag_name == 'textarea') ? field.text : field.value
        assert_match(/#{value}/, field_value, "Field #{ label.inspect } for sample #{ index } was unexpected")
      end
    end
  end
end

Given /^the sample "([^\"]+)" has the Taxon ID "([^\"]+)"$/ do |name,id|
  sample = Sample.find_by_name(name) or raise StandardError, "Cannot find sample with name #{ name.inspect }"
  sample.sample_metadata.sample_taxon_id = id
  sample.save!
end

Given /^the sample "([^\"]+)" has the common name "([^\"]+)"$/ do |name,common_name|
  sample = Sample.find_by_name(name) or raise StandardError, "Cannot find sample with name #{ name.inspect }"
  sample.sample_metadata.sample_common_name = common_name
  sample.save!
end

Given /^the sample "([^\"]+)" belongs to the study "([^\"]+)"$/ do |sample_name, study_name|
  sample = Sample.find_by_name(sample_name) or raise StandardError, "Cannot find sample with name #{ sample_name.inspect }"
  study  = Study.find_by_name(study_name) or raise StandardError, "Cannot find study with name #{ study_name.inspect }"
  study.samples << sample
end

Then /^the reference genome for the sample "([^\"]+)" should be "([^\"]+)"$/ do |name, genome|
  sample = Sample.find_by_name(name) or raise StandardError, "Cannot find sample with name #{ name.inspect }"
  assert_equal(genome, sample.sample_metadata.reference_genome.name)
end

Then /^the sample "([^\"]+)" should exist$/ do |name|
  assert_not_nil(Sample.find_by_name(name), "The sample #{name.inspect} does not exist")
end

Then /^the sample "([^\"]+)" should have an associated sample tube$/ do |name|
  sample = Sample.find_by_name(name) or raise StandardError, "Cannot find sample with name #{ name.inspect }"
  assert(!sample.assets.empty?, 'No associated sample tubes')
end

When /^I get the XML for the sample "([^\"]+)"$/ do |name|
  sample = Sample.find_by_name(name) or raise StandardError, "Cannot find sample with name #{ name.inspect }"
  visit(url_for(:controller => 'samples', :action => 'show', :id => sample, :format => :xml))
end

Given /^I have a sample called "([^"]*)" with metadata$/ do |name|
  sample = Factory :sample, :name => name
end

Given /^the sample "([^"]*)" has a supplier name of "([^"]*)"$/ do |sample_name, supplier_name|
  sample = Sample.find_by_name(sample_name)
  sample.sample_metadata.update_attributes!(:supplier_name => supplier_name)
end

Given /^the sample "([^\"]+)" is in the (sample tube|well) "([^\"]+)"$/ do |sample_name, asset_type, asset_name|
  sample = Sample.find_by_name(sample_name) or raise StandardError, "Cannot find sample #{sample_name.inspect}"
  asset   = Asset.find_by_name(asset_name) or raise StandardError, "Cannot find sample tube #{asset_name.inspect}"
  asset.aliquots.clear
  asset.aliquots.create!(:sample => sample)
end

Then /^sample "([^"]*)" should have an accession number of "([^"]*)"$/ do |sample_name, accession_number|
  sample = Sample.find_by_name(sample_name) or raise StandardError, "Cannot find sample #{sample_name.inspect}"
  assert_equal accession_number, sample.sample_metadata.sample_ebi_accession_number
end

Given /^the sample "([^"]*)" should not have an accession number$/ do |sample_name|
  sample = Sample.find_by_name(sample_name) or raise StandardError, "Cannot find sample #{sample_name.inspect}"
  assert_nil sample.sample_metadata.sample_ebi_accession_number
end

Given /^I run the "([^\"]+)" cron script$/ do |script_name|
  eval File.read("#{RAILS_ROOT}/lib/cron_scripts/#{script_name}")
end

GivenSampleMetadata(:sample_ebi_accession_number, /^the sample "([^\"]+)" has the accession number "([^\"]+)"$/)

When /^I generate an? accession number for sample "([^\"]+)"$/ do |sample_name|
 Then %Q{I am on the show page for sample "#{sample_name}"}
 When %Q{I follow "Generate Accession Number"}
end

When /^I update an? accession number for sample "([^\"]+)"$/ do |sample_name|
 Then %Q{I am on the show page for sample "#{sample_name}"}
 When %Q{I follow "Update EBI Sample data"}
end


Given /^sample "([^"]*)" came from a sample manifest$/ do |sample_name|
  sample = Sample.find_by_name(sample_name)
  sample_manifest = Factory(:sample_manifest, :id => 1)
  sample.update_attributes!(:sample_manifest => sample_manifest)
end

Given /^study "([^\"]+)" has the following samples in sample tubes:$/ do |study_name, table|
  study = Study.find_by_name(study_name) or raise StandardError, "Cannot find study #{study_name.inspect}"
  table.hashes.each do |details|
    sample_tube_name = details['sample tube']
    sample_name = details['sample']

    sample = Sample.find_by_name(sample_name)
    Given %Q{I have a sample called "#{sample_name}"} unless sample
    Given %Q{sample "#{sample_name}" is in a sample tube named "#{sample_tube_name}"}
    And %Q{the sample "#{sample_name}" belongs to the study "#{study_name}"}
    And %Q{the asset "#{sample_tube_name}" belongs to study "#{study_name}"}

  end
end

Then /^the sample "([^"]*)" should belong to the study named "([^"]*)"$/ do |sample_name, study_name|
  sample = Sample.find_by_name(sample_name) or raise StandardError, "Cannot find sample #{sample_name.inspect}"
  study  = Study.find_by_name(study_name) or raise StandardError, "Cannot find study #{study_name.inspect}"
  assert study.samples.include?(sample)
end
Then /^the sample "([^"]*)" should not belong to the study named "([^"]*)"$/ do |sample_name, study_name|
  sample = Sample.find_by_name(sample_name) or raise StandardError, "Cannot find sample #{sample_name.inspect}"
  study  = Study.find_by_name(study_name) or raise StandardError, "Cannot find study #{study_name.inspect}"
  assert !study.samples.include?(sample)
end

Given /^a sample named "([^\"]+)" exists for accession/ do |sample_name|
  study_name = "study for sample #{sample_name}"
  Given %Q{a study named "#{study_name}" exists for accession}
  Given %Q{the sample named "#{sample_name}" exists with ID 200}
  And %Q{I am the owner of sample "sample"}
  And %Q{the sample "#{sample_name}" belongs to the study "#{study_name}"}
  And %Q{the sample "#{sample_name}" has the Taxon ID "99999"}
  And %Q{the sample "#{sample_name}" has the common name "Human"}
end

Given /^the Sanger sample ID of the last sample is "([^\"]+)"$/ do |id|
  sample = Sample.last or raise StandardError, "There appear to be no samples"
  sample.update_attributes!(:sanger_sample_id => id)
end

Given /^all samples have a Sanger sample ID based on "([^\"]+)"$/ do |id|
  Sample.all.each_with_index do |sample, index|
    sample.update_attributes!(:sanger_sample_id => "#{id}#{'%02d' % (index+1)}")
  end
end

Given /^the supplier sample name of the last sample is "([^\"]+)"$/ do |name|
  sample = Sample.last or raise StandardError, "There appear to be no samples"
  sample.update_attributes!(:sample_metadata_attributes => { :supplier_name => name })
end

Given /^the sample called "([^\"]+)" is (#{Sample::GENDERS.join('|')})$/ do |name, gender|
  sample = Sample.find_by_name(name) or raise StandardError, "Cannot find the sample #{name.inspect}"
  sample.update_attributes!(:sample_metadata_attributes => { :gender => gender })
end

Given /^the GC content of the sample called "([^\"]+)" is (#{Sample::GC_CONTENTS.join('|')})$/ do |name, gc_content|
  sample = Sample.find_by_name(name) or raise StandardError, "Cannot find the sample #{name.inspect}"
  sample.update_attributes!(:sample_metadata_attributes => { :gc_content => gc_content })
end

Given /^the DNA source of the sample called "([^\"]+)" is (#{Sample::DNA_SOURCES.join('|')})$/ do |name, source|
  sample = Sample.find_by_name(name) or raise StandardError, "Cannot find the sample #{name.inspect}"
  sample.update_attributes!(:sample_metadata_attributes => { :dna_source => source })
end

Given /^the SRA status of the sample called "([^\"]+)" is (#{Sample::SRA_HOLD_VALUES.join('|')})$/ do |name, sra_status|
  sample = Sample.find_by_name(name) or raise StandardError, "Cannot find the sample #{name.inspect}"
  sample.update_attributes!(:sample_metadata_attributes => { :sample_sra_hold => sra_status })
end

Given /^the sample called "([^\"]+)" is (#{Sample::AGE_REGEXP}) old$/ do |name, age|
  sample = Sample.find_by_name(name) or raise StandardError, "Cannot find the sample #{name.inspect}"
  sample.update_attributes!(:sample_metadata_attributes => { :age => age })
end

Given /^the dosage of the sample called "([^\"]+)" is (#{Sample::DOSE_REGEXP})/ do |name, dose|
  sample = Sample.find_by_name(name) or raise StandardError, "Cannot find the sample #{name.inspect}"
  sample.update_attributes!(:sample_metadata_attributes => { :dose => dose })
end

Given /^there are no samples$/ do
  Sample.destroy_all
end
