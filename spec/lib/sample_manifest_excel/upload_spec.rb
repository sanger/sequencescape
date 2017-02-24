require 'rails_helper'

RSpec.describe SampleManifestExcel::Upload, type: :model, sample_manifest_excel: true do

  let(:column_list) { build(:column_list_for_plate) }

  it 'should be valid if all of the headings relate to a column' do
    heading_names = column_list.headings.reverse
    heading_names.pop
    upload = SampleManifestExcel::Upload.new(heading_names, column_list)
    expect(upload.columns.count).to eq(heading_names.length) 
    expect(upload).to be_valid
  end

  it 'should be invalid if any of the headings do not relate to a column' do
    dodgy_column = build(:column)
    heading_names = column_list.headings << dodgy_column.heading
    upload = SampleManifestExcel::Upload.new(heading_names, column_list)
    expect(upload).to_not be_valid
    expect(upload.errors.full_messages.to_s).to include(dodgy_column.heading) 
  end

  it 'should be invalid if there is no sanger sample id column' do
    column_list = build(:column_list)
    upload = SampleManifestExcel::Upload.new(column_list.headings, column_list)
    expect(upload).to_not be_valid
  end

  context 'Row' do

    let(:sample) { create(:sample_with_well) }
    let(:valid_values) { column_list.column_values(
                        sanger_sample_id: sample.id,
                        sanger_plate_id: sample.wells.first.plate.sanger_human_barcode,
                        well: sample.wells.first.map.description
                        ) }

    it '#value returns value for specified key' do
      expect(SampleManifestExcel::Upload::SampleRow.new(1, valid_values, column_list).value(:sanger_sample_id)).to eq(sample.id)
    end

    it '#at returns value at specified index (offset by 1)' do
      expect(SampleManifestExcel::Upload::SampleRow.new(1, valid_values, column_list).at(column_list.find_by(:name, :sanger_sample_id).number)).to eq(sample.id)
    end

    it '#first? is true if this is the first row' do
      expect(SampleManifestExcel::Upload::SampleRow.new(1, valid_values, column_list)).to be_first
    end

    it 'is not valid without a valid row number' do
      expect(SampleManifestExcel::Upload::SampleRow.new(1, valid_values, column_list)).to be_valid
      expect(SampleManifestExcel::Upload::SampleRow.new(nil, valid_values, column_list)).to_not be_valid
      expect(SampleManifestExcel::Upload::SampleRow.new('nil', valid_values, column_list)).to_not be_valid
    end

    it 'is not valid without some data' do
      expect(SampleManifestExcel::Upload::SampleRow.new(1, nil, column_list)).to_not be_valid
    end

    it 'is not valid without some columns' do
      expect(SampleManifestExcel::Upload::SampleRow.new(1, valid_values, nil)).to_not be_valid
    end

    it 'is not valid without an associated sample' do
      column_list = build(:column_list_for_plate)
      expect(SampleManifestExcel::Upload::SampleRow.new(1, column_list.column_values, column_list)).to_not be_valid
    end

    it 'not be valid unless the sample has a primary receptacle' do
      expect(SampleManifestExcel::Upload::SampleRow.new(1, column_list.column_values(
                                                  sanger_sample_id: create(:sample).id
                                                  ), column_list)).to_not be_valid
    end

    context 'sample container' do
      it 'for plate is only valid if barcode and location match' do
        column_list = build(:column_list_for_plate)
        valid_values = column_list.column_values(sanger_sample_id: sample.id, sanger_plate_id: sample.wells.first.plate.sanger_human_barcode)
        expect(SampleManifestExcel::Upload::SampleRow.new(1, valid_values, column_list)).to_not be_valid

        column_list = build(:column_list_for_plate)
        valid_values = column_list.column_values(sanger_sample_id: sample.id, well: sample.wells.first.map.description)
        expect(SampleManifestExcel::Upload::SampleRow.new(1, valid_values, column_list)).to_not be_valid
      end

      it 'for tube is only valid if barcodes match' do
        tube = create(:sample_tube)
        column_list = build(:column_list_for_tube)
        valid_values = column_list.column_values(sanger_sample_id: tube.sample.id, sanger_tube_id: tube.sample.assets.first.sanger_human_barcode)
        expect(SampleManifestExcel::Upload::SampleRow.new(1, valid_values, column_list)).to be_valid

        column_list = build(:column_list_for_tube)
        valid_values = column_list.column_values(sanger_sample_id: tube.sample.id)
        expect(SampleManifestExcel::Upload::SampleRow.new(1, valid_values, column_list)).to_not be_valid
      end
    end
  end
end
