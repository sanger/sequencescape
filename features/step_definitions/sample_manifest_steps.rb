#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2007-2011,2011,2012,2013,2015 Genome Research Ltd.
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
  expected_results_table.diff!(table(fetch_table('table#study_list')))
end

def sequence_sanger_sample_ids_for(plate)
  plate.wells.walk_in_column_major_order do |well, index|
    well.primary_aliquot.sample.update_attributes!(:sanger_sample_id => yield(index))
  end
end

Given /^I reset all of the sanger sample ids to a known number sequence$/ do
  # raise StandardError, "Only works for plate manifests!" if Plate.count == 0

  index = 0
  Plate.all(:order => 'id ASC').each do |plate|
    sequence_sanger_sample_ids_for(plate) do |well_index|
      "sample_#{index+well_index}"
    end
    index += plate.size
  end
  SampleTube.all(:order => 'id ASC').each_with_index do |tube, idx|
    tube.aliquots.first.sample.update_attributes!(:sanger_sample_id=>"tube_sample_#{idx+1}")
  end
  LibraryTube.all(:order => 'id ASC').each_with_index do |tube, idx|
    tube.aliquots.first.sample.update_attributes!(:sanger_sample_id=>"tube_sample_#{idx+1}")
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

    expected_data.each do |k,v|
      next if v.blank?
      next if [:sanger_sample_id,:empty_supplier_sample_name,:supplier_name,:sample_taxon_id].include?(:"#{k}")
      assert_equal(v,sample.sample_metadata.send(k), "Sample #{k} invalid for #{sanger_sample_id}")
    end

  end
end

Then /^the sample accession numbers should be:$/ do |table|
  table.hashes.each do |expected_data|
    sanger_sample_id = expected_data[:sanger_sample_id]
    sample = Sample.find_by_sanger_sample_id(sanger_sample_id) or raise StandardError, "Could not find sample #{sanger_sample_id}"
    assert_equal(expected_data[:accession_number],sample.sample_metadata.sample_ebi_accession_number)
  end
end

Then /^the sample reference genomes should be:$/ do |table|
  table.hashes.each do |expected_data|
    sanger_sample_id = expected_data[:sanger_sample_id]
    sample = Sample.find_by_sanger_sample_id(sanger_sample_id) or raise StandardError, "Could not find sample #{sanger_sample_id}"
    assert_equal(expected_data[:reference_genome],sample.sample_metadata.reference_genome.name)
  end
end

Then /^the samples should be tagged in library and multiplexed library tubes with:$/ do |table|
  pooled_aliquots = MultiplexedLibraryTube.last.aliquots.map {|a| [a.sample.sanger_sample_id, a.tag.map_id]}
  table.hashes.each do |expected_data|
    lt = LibraryTube.find_by_barcode(expected_data[:tube_barcode].gsub('NT',''))
    assert_equal 1, lt.aliquots.count
    assert_equal expected_data[:sanger_sample_id], lt.aliquots.first.sample.sanger_sample_id, "sanger_sample_id: #{expected_data[:sanger_sample_id]} #{lt.aliquots.first.sample.sanger_sample_id}"
    assert_equal expected_data[:tag_group], lt.aliquots.first.tag.try(:tag_group).try(:name), "tag_group: #{expected_data[:tag_group]} #{lt.aliquots.first.tag.try(:tag_group).try(:name)}"
    assert_equal expected_data[:tag_index].to_i, lt.aliquots.first.tag.try(:map_id), "tag_index: #{expected_data[:tag_index]} #{lt.aliquots.first.tag.try(:map_id)}"
    assert_equal expected_data[:tag2_group], lt.aliquots.first.tag2.try(:tag_group).try(:name)||'', "tag2_group: #{expected_data[:tag2_group]} #{lt.aliquots.first.tag2.try(:tag_group).try(:name)||''}"
    assert_equal expected_data[:tag2_index].to_i, lt.aliquots.first.tag2.try(:map_id)||0, "tag2_index: #{expected_data[:tag2_index]} #{lt.aliquots.first.tag2.try(:map_id)||''}"
    assert_equal expected_data[:library_type], lt.aliquots.first.library_type, "library_type: #{expected_data[:library_type]} #{lt.aliquots.first.library_type}"
    assert_equal expected_data[:insert_size_from].to_i, lt.aliquots.first.insert_size_from, "insert_size_from: #{expected_data[:insert_size_from]} #{lt.aliquots.first.insert_size_from}"
    assert_equal expected_data[:insert_size_to].to_i, lt.aliquots.first.insert_size_to, "insert_size_to: #{expected_data[:insert_size_to]} #{lt.aliquots.first.insert_size_to}"
    assert pooled_aliquots.delete([expected_data[:sanger_sample_id],expected_data[:tag_index].to_i]), "Couldn't find #{expected_data[:sanger_sample_id]} with #{expected_data[:tag_index]} in MX tube."
  end
  assert pooled_aliquots.empty?, "MX tube contains extra samples: #{pooled_aliquots.inspect}"
end

Given /^a manifest has been created for "([^"]*)"$/ do |study_name|
  step(%Q{I follow "Create manifest for plates"})
	step(%Q{I select "#{study_name}" from "Study"})
  step(%Q{I select "default layout" from "Template"})
	step(%Q{I select "Test supplier name" from "Supplier"})
	step(%Q{I select "xyz" from "Barcode printer"})
	step(%Q{I fill in the field labeled "Plates required" with "1"})
  step(%Q{I select "default layout" from "Template"})
	step(%Q{I press "Create manifest and print labels"})
	step %Q{I should see "Manifest_"}
	step %Q{I should see "Download Blank Manifest"}
	step(%Q{3 pending delayed jobs are processed})
	step %Q{study "#{study_name}" should have 96 samples}
	step(%Q{I reset all of the sanger sample ids to a known number sequence})
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
    tempfile.write(SampleManifest.last.generated_document.current_data)
    tempfile.flush
    tempfile.open

    spreadsheet = Spreadsheet.open(tempfile.path)
    @worksheet   =spreadsheet.worksheets.first
  end

  table.rows.each_with_index do |row,index|
    expected = [ Barcode.barcode_to_human(Barcode.calculate_barcode(Plate.prefix, row[0].to_i)), row[1] ]
    got      = [ @worksheet[offset+index,0], @worksheet[offset+index,1] ]
    assert_equal(expected, got, "Unexpected manifest row #{index}")
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

Given /^the sample manifest with ID (\d+) is for (\d+) libraries?$/ do |id, count|
  manifest = SampleManifest.find(id)
  manifest.update_attributes!(:asset_type => 'multiplexed_library', :count => count.to_i)
end

Given /^the sample manifest with ID (\d+) has been processed$/ do |id|
  manifest = SampleManifest.find(id)
  manifest.generate
  step(%Q{3 pending delayed jobs are processed})
end

Given /^sample tubes are expected by the last manifest$/ do
  SampleManifest.last.update_attributes(:barcodes=>SampleTube.all.map(&:sanger_human_barcode))
end

Given /^library tubes are expected by the last manifest$/ do
  SampleManifest.last.update_attributes(:barcodes=>LibraryTube.all.map(&:sanger_human_barcode))
end

Then /^print any manifest errors for debugging$/ do
  if SampleManifest.last.last_errors.present?
    puts "="*80
    SampleManifest.last.last_errors.each {|error| puts error}
    puts "="*80
  end
end
