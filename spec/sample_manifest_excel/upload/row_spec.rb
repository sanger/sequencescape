# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SampleManifestExcel::Upload::Row, type: :model, sample_manifest_excel: true do
  before(:all) do
    SampleManifestExcel.configure do |config|
      config.folder = File.join('spec', 'data', 'sample_manifest_excel')
      config.load!
    end
  end

  let(:columns)       { SampleManifestExcel.configuration.columns.tube_library_with_tag_sequences.dup }
  let(:data)          do
    [sample_tube.samples.first.assets.first.human_barcode, sample_tube.samples.first.sanger_sample_id,
     'AA', '', 'My reference genome', 'My New Library Type', 200, 1500, 'SCG--1222_A01', '', 1, 1, 'Unknown', '', '', '',
     'Cell Line', 'Nov-16', 'Nov-16', '', 'No', '', 'OTHER', '', '', '', '', '', 'SCG--1222_A01',
     9606, 'Homo sapiens', '', '', '', '', 11, 'Unknown']
  end
  let!(:library_type) { create(:library_type, name: 'My New Library Type') }
  let!(:reference_genome) { create(:reference_genome, name: 'My reference genome') }
  let!(:sample_tube)  { create(:sample_tube_with_sanger_sample_id) }
  let!(:tag_group)    { create(:tag_group) }

  it 'is not valid without row number' do
    expect(SampleManifestExcel::Upload::Row.new(number: 'one', data: data, columns: columns)).to_not be_valid
    expect(SampleManifestExcel::Upload::Row.new(data: data, columns: columns)).to_not be_valid
  end

  it 'is not valid without some data' do
    expect(SampleManifestExcel::Upload::Row.new(number: 1, columns: columns)).to_not be_valid
  end

  it 'is not valid without some columns' do
    expect(SampleManifestExcel::Upload::Row.new(number: 1, data: data)).to_not be_valid
  end

  it '#value returns value for specified key' do
    expect(SampleManifestExcel::Upload::Row.new(number: 1, data: data, columns: columns).value(:sanger_sample_id)).to eq(sample_tube.samples.first.sanger_sample_id)
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

  it 'is not valid unless metadata is valid' do
    SampleManifestExcel::Upload::Row.new(number: 1, data: data, columns: columns)
    expect(SampleManifestExcel::Upload::Row.new(number: 1, data: data, columns: columns)).to be_valid
    data[16] = 'Cell-line'
    expect(SampleManifestExcel::Upload::Row.new(number: 1, data: data, columns: columns)).to_not be_valid
  end

  it 'updates the aliquot with the specialised fields' do
    row = SampleManifestExcel::Upload::Row.new(number: 1, data: data, columns: columns)
    row.update_specialised_fields(tag_group)
    aliquot = row.aliquot
    expect(aliquot.tag.oligo).to eq('AA')
    expect(aliquot.tag2).to be nil
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
    row.update_sample(tag_group, false)
    row.metadata
    expect(row).to be_sample_updated
  end

  it 'knows if it is empty' do
    empty_data = [sample_tube.samples.first.assets.first.human_barcode, sample_tube.samples.first.sanger_sample_id,
                  '', '', '', '', '', '', '', '', '', '', '', '', '',
                  '', '', '', '', '', '', '', '', '', '', '', '', '', '', '',
                  '', '', '', '', '', '', '', sample_tube.samples.first.sanger_sample_id, '']
    row = SampleManifestExcel::Upload::Row.new(number: 1, data: data, columns: columns)
    empty_row = SampleManifestExcel::Upload::Row.new(number: 1, data: empty_data, columns: columns)
    expect(row.empty?).to be false
    expect(empty_row.empty?).to be true
  end

  context 'aliquot transfer on multiplex library tubes' do
    attr_reader :rows

    let!(:library_tubes) { create_list(:library_tube_with_barcode, 5) }
    let!(:mx_library_tube) { create(:multiplexed_library_tube) }
    let(:tags) { SampleManifestExcel::Tags::ExampleData.new.take(0, 4) }

    before(:each) do
      @rows = []
      library_tubes.each_with_index do |tube, i|
        create(:external_multiplexed_library_tube_creation_request, asset: tube, target_asset: mx_library_tube)
        row_data = data.dup
        row_data[0] = tube.samples.first.assets.first.human_barcode
        row_data[1] = tube.samples.first.sanger_sample_id
        row_data[2] = tags[i][:i7]
        row_data[3] = tags[i][:i5]
        rows << SampleManifestExcel::Upload::Row.new(number: i + 1, data: row_data, columns: columns)
      end
    end

    it 'transfers stuff' do
      rows.each do |row|
        row.update_sample(tag_group, false)
        row.transfer_aliquot
      end
      expect(rows.all?(&:aliquot_transferred?)).to be_truthy
      expect(rows.all?(&:reuploaded?)).to be_falsey
      mx_library_tube.samples.each_with_index do |sample, i|
        expect(sample.aliquots.first.tag.oligo).to eq(tags[i][:i7])
        expect(sample.aliquots.first.tag2.oligo).to eq(tags[i][:i5])
        sample.primary_receptacle.requests.each do |request|
          expect(request.state).to eq('passed')
        end
      end
    end
  end

  context 'previously transferred aliquot on multiplex library tubes' do
    attr_reader :rows

    let!(:library_tubes) { create_list(:tagged_library_tube, 5) }
    let!(:mx_library_tube) { create(:multiplexed_library_tube) }
    let(:tags) { SampleManifestExcel::Tags::ExampleData.new.take(0, 4) }

    before(:each) do
      @rows = []
      library_tubes.each_with_index do |tube, i|
        rq = create(:external_multiplexed_library_tube_creation_request, asset: tube, target_asset: mx_library_tube)
        rq.manifest_processed!
        row_data = data.dup
        row_data[0] = tube.samples.first.assets.first.human_barcode
        row_data[1] = tube.samples.first.sanger_sample_id
        row_data[2] = tags[i][:i7]
        row_data[3] = tags[i][:i5]
        rows << SampleManifestExcel::Upload::Row.new(number: i + 1, data: row_data, columns: columns)
      end
    end

    it 'transfers stuff' do
      rows.each do |row|
        row.update_sample(tag_group, false)
        row.transfer_aliquot
      end
      expect(rows.all?(&:aliquot_transferred?)).to be_truthy
      expect(rows.all?(&:reuploaded?)).to be_truthy
      mx_library_tube.samples.each_with_index do |sample, i|
        expect(sample.aliquots.first.tag.oligo).to eq(tags[i][:i7])
        expect(sample.aliquots.first.tag2.oligo).to eq(tags[i][:i5])
        sample.primary_receptacle.requests.each do |request|
          expect(request.state).to eq('passed')
        end
      end
    end
  end

  after(:all) do
    SampleManifestExcel.reset!
  end
end
