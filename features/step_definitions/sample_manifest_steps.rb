Given /^a supplier called "(.*)" exists$/ do |supplier_name|
  Supplier.create!({:name => supplier_name })
end

Given /^the study "(.*)" has a abbreviation$/ do |study_name|
  study = Study.find_by_name(study_name)
  study.study_metadata.study_name_abbreviation = "TEST"
end

Given /^sample information is updated from the manifest for study "([^"]*)"$/ do |study_name|
  study = Study.find_by_name(study_name) or raise StandardError, "Cannot find study #{study_name.inspect}"
  study.samples.each_with_index do |sample,index|
    sample.update_attributes!(
      :sanger_sample_id => sample.name,
      :sample_metadata_attributes => {
        :gender           => "Female",
        :dna_source       => "Blood",
        :sample_sra_hold  => "Hold"
      }
    )
    sample.name = "#{study.abbreviation}#{index+1}"
    sample.save_without_validation
  end
end

Given /^the last sample has been updated by a manifest$/ do
  sample = Sample.last or raise StandardError, "There appear to be no samples"
  sample.update_attributes!(:updated_by_manifest => true)
end

Then /^study "([^"]*)" should have (\d+) samples$/ do |study_name, number_of_samples|
  study = Study.find_by_name(study_name)
  assert_equal number_of_samples.to_i, study.samples.size
end

Then /^I should see the manifest table:$/ do |expected_results_table|
  expected_results_table.diff!(table(tableish('table#study_list tr', 'td,th')))
end

def sequence_sanger_sample_ids_for(plate)
  plate.wells.walk_in_column_major_order do |well, index|
    well.primary_aliquot.sample.update_attributes!(:sanger_sample_id => yield(index))
  end
end

Given /^I reset all of the sanger sample ids to a known number sequence$/ do
  raise StandardError, "Only works for plate manifests!" if Plate.count == 0

  index = 0
  Plate.all(:order => 'id ASC').each do |plate|
    sequence_sanger_sample_ids_for(plate) do |well_index|
      "sample_#{index+well_index}"
    end
    index += plate.size
  end
end

Then /^sample "([^"]*)" should have empty supplier name set to "([^"]*)"$/ do |sanger_sample_id, boolean_string|
  sample = Sample.find_by_sanger_sample_id(sanger_sample_id)
  if boolean_string == "true"
    assert sample.empty_supplier_sample_name
  else
    assert ! sample.empty_supplier_sample_name
  end
end

Given /^the Sanger sample IDs will be sequentially generated$/ do
  SangerSampleId::Factory.instance_variable_set(:@instance, Object.new.tap do |instance|
    def instance.next!
      @counter = (@counter || 0) + 1
    end
  end)
end

Then /^the samples table should look like:$/ do |table|
  table.hashes.each do |expected_data|
    sanger_sample_id = expected_data[:sanger_sample_id]
    sample = Sample.find_by_sanger_sample_id(sanger_sample_id) or raise StandardError, "Could not find sample #{sanger_sample_id}"

    if expected_data[:empty_supplier_sample_name] == "true"
      assert(sample.empty_supplier_sample_name, "Supplier sample name not nil for #{sanger_sample_id}")
    else
      assert_equal(expected_data[:supplier_name], sample.sample_metadata.supplier_name, "Supplier sample name invalid for #{sanger_sample_id}")
    end

    if sample.sample_metadata.sample_taxon_id.blank?
      assert_nil(sample.sample_metadata.sample_taxon_id, "Sample taxon ID not nil for #{sanger_sample_id}")
    else
      assert_equal(expected_data[:sample_taxon_id].to_i, sample.sample_metadata.sample_taxon_id, "Sample taxon ID invalid for #{sanger_sample_id}")
    end

    unless expected_data[:common_name].blank?
      assert_equal(expected_data[:common_name], sample.sample_metadata.sample_common_name, "Sample common name invalid for #{sanger_sample_id}")
    end
  end
end

Given /^a manifest has been created for "([^"]*)"$/ do |study_name|
  When %Q{I follow "Create manifest for plates"}
  When %Q{I select "#{study_name}" from "Study"}
  When %Q{I select "default layout" from "Template"}
  And %Q{I select "Test supplier name" from "Supplier"}
  And %Q{I select "xyz" from "Barcode printer"}
  And %Q{I fill in the field labeled "Count" with "1"}
  And %Q{I select "default layout" from "Template"}
  When %Q{I press "Create manifest and print labels"}
  Then %Q{I should see "Manifest_"}
  Then %Q{I should see "Download Blank Manifest"}
  Given %Q{3 pending delayed jobs are processed}
  Then %Q{study "#{study_name}" should have 96 samples}
  Given %Q{I reset all of the sanger sample ids to a known number sequence}
end

Then /^the sample controls and resubmits should look like:$/ do |table|
  found = table.hashes.map do |expected_data|
    sample = Sample.find_by_sanger_sample_id(expected_data[:sanger_sample_id]) or raise StandardError, "Cannot find sample by sanger ID #{expected_data[:sanger_sample_id]}"
    {
      'sanger_sample_id' => expected_data[:sanger_sample_id],
      'supplier_name'             => sample.sample_metadata.supplier_name,
      'is_control'       => sample.control.to_s,
      'is_resubmit'      => sample.sample_metadata.is_resubmitted.to_s
    }
  end
  assert_equal(table.hashes, found)
end

When /^I visit the sample manifest new page without an asset type$/ do
  visit('/sdb/sample_manifests/new')
end

Given /^plate "([^"]*)" has samples with known sanger_sample_ids$/ do |plate_barcode|
  sequence_sanger_sample_ids_for(Plate.find_by_barcode(plate_barcode)) do |index|
    "ABC_#{index}"
  end
end

Then /^the last created sample manifest should be:$/ do |table|
  offset = 9
  Tempfile.open('testfile.xls') do |tempfile|
    tempfile.write(SampleManifest.last.generated.data)
    tempfile.flush
    tempfile.open

    spreadsheet = Spreadsheet.open(tempfile.path)
    @worksheet   =spreadsheet.worksheets.first
  end

  table.rows.each_with_index do |row,index|
    assert_equal Barcode.barcode_to_human(Barcode.calculate_barcode(Plate.prefix, row[0].to_i)), @worksheet[offset+index,0]
    assert_equal row[1], @worksheet[offset+index,1]
  end
end

When /^the sample manifest with ID (\d+) is owned by study "([^\"]+)"$/ do |id, name|
  manifest = SampleManifest.find(id)
  study    = Study.find_by_name(name) or raise StandardError, "Cannot find study #{name.inspect}"
  manifest.update_attributes!(:study => study)
end

When /^the sample manifest with ID (\d+) is supplied by "([^\"]+)"$/ do |id, name|
  manifest = SampleManifest.find(id)
  supplier = Supplier.find_by_name(name) or raise StandardError, "Cannot find supplier #{name.inspect}"
  manifest.update_attributes!(:supplier => supplier)
end

Given /^the sample manifest with ID (\d+) is for (\d+) sample tube$/ do |id, count|
  manifest = SampleManifest.find(id)
  manifest.update_attributes!(:asset_type => '1dtube', :count => count.to_i)
end

Given /^the sample manifest with ID (\d+) is for (\d+) plates?$/ do |id, count|
  manifest = SampleManifest.find(id)
  manifest.update_attributes!(:asset_type => 'plate', :count => count.to_i)
end

Given /^the sample manifest with ID (\d+) has been processed$/ do |id|
  manifest = SampleManifest.find(id)
  manifest.generate
  Given %Q{3 pending delayed jobs are processed}
end
