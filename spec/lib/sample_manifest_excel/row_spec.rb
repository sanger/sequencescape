require 'rails_helper'

RSpec.describe SampleManifestExcel::Upload::Row, type: :model, sample_manifest_excel: true do

  include SampleManifestExcel::Helpers

  let(:folder)                  { File.join('spec', 'data', 'sample_manifest_excel') }
  let(:yaml)                    { load_file(folder, 'columns') }
  let(:conditional_formattings) { SampleManifestExcel::ConditionalFormattingDefaultList.new(load_file(folder, 'conditional_formattings')) }
  let(:column_list)             { SampleManifestExcel::ColumnList.new(yaml, conditional_formattings) }
  let(:manifest_types)          { SampleManifestExcel::ManifestTypeList.new(load_file(folder, 'manifest_types')) }
  let!(:library_type)           { create(:library_type, name: 'My New Library Type') }
  let!(:sample_tube)            { create(:sample_tube) }
  let(:headings)                { ['SANGER TUBE ID',  'SANGER SAMPLE ID',  'TAG OLIGO', 'TAG2 OLIGO', 'LIBRARY TYPE',  'INSERT SIZE FROM',  'INSERT SIZE TO',  'SUPPLIER SAMPLE NAME',  'COHORT',  'VOLUME (ul)', 'CONC. (ng/ul)', 'GENDER',  'COUNTRY OF ORIGIN', 'GEOGRAPHICAL REGION', 'ETHNICITY', 'DNA SOURCE',  'DATE OF SAMPLE COLLECTION (MM/YY or YYYY only)',  'DATE OF DNA EXTRACTION (MM/YY or YYYY only)', 'IS SAMPLE A CONTROL?',  'IS RE-SUBMITTED SAMPLE?', 'DNA EXTRACTION METHOD', 'SAMPLE PURIFIED?',  'PURIFICATION METHOD', 'CONCENTRATION DETERMINED BY', 'DNA STORAGE CONDITIONS',  'MOTHER (optional)', 'FATHER (optional)', 'SIBLING (optional)',  'GC CONTENT',  'PUBLIC NAME', 'TAXON ID',  'COMMON NAME', 'SAMPLE DESCRIPTION',  'STRAIN',  'SAMPLE VISIBILITY', 'SAMPLE TYPE', 'SAMPLE ACCESSION NUMBER (optional)',  'DONOR ID (required for EGA)', 'PHENOTYPE (required for EGA)'] }
  let(:data)                    { [sample_tube.sample.assets.first.sanger_human_barcode, sample_tube.sample.id, 'AA','', 'My New Library Type', 200, 1500, 'SCG--1222_A01', '', 1, 1, 'Unknown','','','','Cell Line', 'Nov-16', 'Nov-16', '', '', '', 'No', '', 'OTHER', '', '', '', '', '', 'SCG--1222_A01', 9606,  'Homo sapiens', '', '', '', '', '', 11, 'Unknown' ] }
  let(:columns)                 { column_list.extract(headings) }
  let!(:tag_group)              { create(:tag_group) }
  
  it 'is not valid without row number' do
    expect(SampleManifestExcel::Upload::Row.new(number: "one", data: data, columns: columns)).to_not be_valid
    expect(SampleManifestExcel::Upload::Row.new(data: data, columns: columns)).to_not be_valid
  end

  it 'is not valid without some data' do
    expect(SampleManifestExcel::Upload::Row.new(number: 1, columns: columns)).to_not be_valid
  end

  it 'is not valid without some columns' do
    expect(SampleManifestExcel::Upload::Row.new(number: 1, data: data)).to_not be_valid
  end

  it '#value returns value for specified key' do
    expect(SampleManifestExcel::Upload::Row.new(number: 1, data: data, columns: columns).value(:sanger_sample_id)).to eq(sample_tube.sample.id)
  end

  it '#at returns value at specified index (offset by 1)' do
    expect(SampleManifestExcel::Upload::Row.new(number: 1, data: data, columns: columns).at(3)).to eq('AA')
  end

  it '#first? is true if this is the first row' do
    expect(SampleManifestExcel::Upload::Row.new(number: 1, data: data, columns: columns)).to be_first
  end

  it 'is not valid without a primary receptacle or sample' do
    sample = create(:sample)
    data[1] = sample.id
    expect(SampleManifestExcel::Upload::Row.new(number: 1, data: data, columns: columns)).to_not be_valid
    data[1] = 999999
    row = SampleManifestExcel::Upload::Row.new(number: 1, data: data, columns: columns)
    expect(row).to_not be_valid
    expect(row.errors.full_messages).to include('Row 1 - Sample can\'t be blank.')
  end

  it 'is not valid unless all specialised fields are valid' do
    expect(SampleManifestExcel::Upload::Row.new(number: 1, data: data, columns: columns)).to be_valid
    data[5] = 'Dodgy library type'
    expect(SampleManifestExcel::Upload::Row.new(number: 1, data: data, columns: columns)).to_not be_valid
    data[5] = 'My New Library Type'
    data[6] = 'one'
    expect(SampleManifestExcel::Upload::Row.new(number: 1, data: data, columns: columns)).to_not be_valid
  end

  it 'updates the aliquot with the specialised fields' do
    row = SampleManifestExcel::Upload::Row.new(number: 1, data: data, columns: columns)
    row.update_specialised_fields(tag_group)
    aliquot = row.aliquot
    expect(aliquot.tag.oligo).to eq('AA')
    expect(aliquot.tag2.oligo).to_not be_present
    expect(aliquot.insert_size_from).to eq(200)
    expect(aliquot.insert_size_to).to eq(1500)
  end

  it 'updates the sample metadata' do
    row = SampleManifestExcel::Upload::Row.new(number: 1, data: data, columns: columns)
    row.update_metadata_fields
    metadata = row.metadata
    expect(metadata.concentration).to eq('1')
    expect(metadata.gender).to eq('Unknown')
    expect(metadata.dna_source).to eq('Cell Line')
    expect(metadata.date_of_sample_collection).to eq('Nov-16')
    expect(metadata.date_of_sample_extraction).to eq('Nov-16')
    expect(metadata.sample_purified).to eq('No')
    expect(metadata.concentration_determined_by).to eq('OTHER')
    expect(metadata.sample_public_name).to eq('SCG--1222_A01')
    expect(metadata.sample_taxon_id).to eq(9606)
    expect(metadata.sample_common_name).to eq('Homo sapiens')
    expect(metadata.donor_id).to eq('11')
    expect(metadata.phenotype).to eq('Unknown')
  end

  it 'updates the sample' do
    row = SampleManifestExcel::Upload::Row.new(number: 1, data: data, columns: columns)
    row.update_sample(tag_group)
    metadata = row.metadata
    expect(row).to be_sample_updated
  end

end