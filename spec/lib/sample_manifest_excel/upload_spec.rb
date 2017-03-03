require 'rails_helper'

RSpec.describe SampleManifestExcel::Upload, type: :model, sample_manifest_excel: true do

  include SampleManifestExcel::Helpers

  let(:folder)                  { File.join('spec', 'data', 'sample_manifest_excel') }
  let(:yaml)                    { load_file(folder, 'columns') }
  let(:conditional_formattings) { SampleManifestExcel::ConditionalFormattingDefaultList.new(load_file(folder, 'conditional_formattings')) }
  let(:column_list)             { SampleManifestExcel::ColumnList.new(yaml, conditional_formattings) }
  let(:manifest_types)          { SampleManifestExcel::ManifestTypeList.new(load_file(folder, 'manifest_types')) }

  it 'should be valid if all of the headings relate to a column' do
    upload = SampleManifestExcel::Upload.new("#{Rails.root}/spec/data/sample_manifest_excel/spreadsheets/tube_library.csv", column_list, 9)
    expect(upload.columns.count).to eq(manifest_types.find_by(:tube_library).columns.length)
    expect(upload).to be_valid
  end

  it 'should be invalid if any of the headings do not relate to a column' do
    upload = SampleManifestExcel::Upload.new("#{Rails.root}/spec/data/sample_manifest_excel/spreadsheets/tube_library_dodgy_column.csv", column_list, 9)
    expect(upload).to_not be_valid
    expect(upload.errors.full_messages.to_s).to include(upload.columns.bad_keys.first)
  end

  it 'should be invalid if there is no sanger sample id column' do
    upload = SampleManifestExcel::Upload.new("#{Rails.root}/spec/data/sample_manifest_excel/spreadsheets/tube_library_no_sanger_sample_id.csv", column_list, 9)
    expect(upload).to_not be_valid
  end

  it "should be invalid if tags are not valid" do
    upload = SampleManifestExcel::Upload.new("#{Rails.root}/spec/data/sample_manifest_excel/spreadsheets/tube_library_invalid_tags.csv", column_list, 9)
    expect(upload).to_not be_valid
  end

  context 'Row' do
    let!(:sample_tube) { create(:sample_tube) }
    let(:headings) { ['SANGER TUBE ID',  'SANGER SAMPLE ID',  'PREPOOLED', 'TAG OLIGO', 'TAG2 OLIGO', 'LIBRARY TYPE',  'INSERT SIZE FROM',  'INSERT SIZE TO',  'SUPPLIER SAMPLE NAME',  'COHORT',  'VOLUME (ul)', 'CONC. (ng/ul)', 'GENDER',  'COUNTRY OF ORIGIN', 'GEOGRAPHICAL REGION', 'ETHNICITY', 'DNA SOURCE',  'DATE OF SAMPLE COLLECTION (MM/YY or YYYY only)',  'DATE OF DNA EXTRACTION (MM/YY or YYYY only)', 'IS SAMPLE A CONTROL?',  'IS RE-SUBMITTED SAMPLE?', 'DNA EXTRACTION METHOD', 'SAMPLE PURIFIED?',  'PURIFICATION METHOD', 'CONCENTRATION DETERMINED BY', 'DNA STORAGE CONDITIONS',  'MOTHER (optional)', 'FATHER (optional)', 'SIBLING (optional)',  'GC CONTENT',  'PUBLIC NAME', 'TAXON ID',  'COMMON NAME', 'SAMPLE DESCRIPTION',  'STRAIN',  'SAMPLE VISIBILITY', 'SAMPLE TYPE', 'SAMPLE ACCESSION NUMBER (optional)',  'DONOR ID (required for EGA)', 'PHENOTYPE (required for EGA)'] }
    let(:data) { [sample_tube.sample.assets.first.sanger_human_barcode, sample_tube.sample.id, 'No', 'AA','', 'Nextera Dual Index qPCR only', 200, 1500, 'SCG--1222_A01', 1, 1, 'Unknown','','','','Cell Line', 'Nov-16', 'Nov-16', '', '', '', 'No', 'OTHER', '', '', '', '', '', 'SCG--1222_A01', 9606,  'Homo sapiens', '', '', '', '', '', 11, 'Unknown' ] }
    let(:columns) { column_list.extract(headings) }

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
      expect(SampleManifestExcel::Upload::Row.new(number: 1, data: data, columns: columns).at(3)).to eq('No')
    end

    it '#first? is true if this is the first row' do
      expect(SampleManifestExcel::Upload::Row.new(number: 1, data: data, columns: columns)).to be_first
    end

    it 'is not valid without a primary receptacle or sample' do
      sample = create(:sample)
      data[1] = sample.id
      expect(SampleManifestExcel::Upload::Row.new(number: 1, data: data, columns: columns)).to_not be_valid
      data[1] = 999999
      expect(SampleManifestExcel::Upload::Row.new(number: 1, data: data, columns: columns)).to_not be_valid
    end

  end
end
