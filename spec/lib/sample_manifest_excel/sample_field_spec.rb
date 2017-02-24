require 'rails_helper'

RSpec.describe SampleManifestExcel::SampleField, type: :model, sample_manifest_excel: true do

  let(:plate_column_list) { build(:column_list_for_plate) }
  let(:tube_column_list) { build(:column_list_for_tube) }
  let!(:sample) { create(:sample_with_well) }

  it 'will have the correct type' do
    expect(SampleManifestExcel::SampleField::SangerPlateId.new).to be_sample_field
  end

  it 'will have a list of subclasses' do
    expect(SampleManifestExcel::SampleField::Base.fields.count).to eq(SampleManifestExcel::SampleField::Base.subclasses.count)
    expect(SampleManifestExcel::SampleField::Base.fields[:sanger_plate_id]).to eq(SampleManifestExcel::SampleField::SangerPlateId)
  end

  it 'sanger plate id should return correct value' do
    row = build(:row, data: plate_column_list.column_values, columns: plate_column_list)
    expect(SampleManifestExcel::SampleField::SangerPlateId.new.update(row: row).value).to eq(plate_column_list.find(:sanger_plate_id).value)                  
  end

  it 'sanger plate id should match equivalent sample value' do
    row = build(:row, data: plate_column_list.column_values, columns: plate_column_list)
    expect(SampleManifestExcel::SampleField::SangerPlateId.new.update(row: row).match?(sample)).to be_falsey
    row = build(:row, data: plate_column_list.column_values(sanger_plate_id: sample.wells.first.plate.sanger_human_barcode), columns: plate_column_list)
    expect(SampleManifestExcel::SampleField::SangerPlateId.new.update(row: row).match?(sample)).to be_truthy 
  end

  it 'well should return correct value' do
    row = build(:row, data: plate_column_list.column_values, columns: plate_column_list)
    expect(SampleManifestExcel::SampleField::Well.new.update(row: row).value).to eq(plate_column_list.find(:well).value)      
  end

  it 'well should match equivalent sample value' do
    row = build(:row, data: plate_column_list.column_values, columns: plate_column_list)
    expect(SampleManifestExcel::SampleField::Well.new.update(row: row).match?(sample)).to be_falsey 
    row = build(:row, data: plate_column_list.column_values(well: sample.wells.first.map.description), columns: plate_column_list)
    expect(SampleManifestExcel::SampleField::Well.new.update(row: row).match?(sample)).to be_truthy 
  end

  it 'sanger sample id should return correct value' do
    row = build(:row, data: plate_column_list.column_values, columns: plate_column_list)
    expect(SampleManifestExcel::SampleField::SangerSampleId.new.update(row: row).value).to eq(plate_column_list.find(:sanger_sample_id).value) 
                  
  end

  it 'sanger sample id should match equivalent sample value' do
    row = build(:row, data: plate_column_list.column_values, columns: plate_column_list)
    expect(SampleManifestExcel::SampleField::SangerSampleId.new.update(row: row).match?(sample)).to be_falsey 
    row = build(:row, data: plate_column_list.column_values(sanger_sample_id: sample.sanger_sample_id), columns: plate_column_list)
    expect(SampleManifestExcel::SampleField::SangerSampleId.new.update(row: row).match?(sample)).to be_truthy 
  end

  it 'donor id should return correct value' do
    row = build(:row, data: plate_column_list.column_values, columns: plate_column_list)
    expect(SampleManifestExcel::SampleField::DonorId.new.update(row: row).value).to eq(plate_column_list.find(:donor_id).value)          
  end

  it 'donor id should match equivalent sample value' do
    row = build(:row, data: plate_column_list.column_values, columns: plate_column_list)
    expect(SampleManifestExcel::SampleField::DonorId.new.update(row: row).match?(sample)).to be_falsey 
    row = build(:row, data: plate_column_list.column_values(donor_id: sample.sanger_sample_id), columns: plate_column_list)
    expect(SampleManifestExcel::SampleField::DonorId.new.update(row: row).match?(sample)).to be_truthy 
  end

  it 'donor id 2 should return correct value' do
    row = build(:row, data: tube_column_list.column_values, columns: tube_column_list)
    expect(SampleManifestExcel::SampleField::DonorId2.new.update(row: row).value).to eq(tube_column_list.find(:donor_id2).value)    
  end

  it 'donor id 2 should match equivalent sample value' do
    row = build(:row, data: tube_column_list.column_values, columns: tube_column_list)
    expect(SampleManifestExcel::SampleField::DonorId2.new.update(row: row).match?(sample)).to be_falsey 
    row = build(:row, data: tube_column_list.column_values(donor_id2: sample.sanger_sample_id), columns: tube_column_list)
    expect(SampleManifestExcel::SampleField::DonorId2.new.update(row: row).match?(sample)).to be_truthy 
  end

  it 'sanger tube id should return correct value' do
    row = build(:row, data: tube_column_list.column_values, columns: tube_column_list)
    expect(SampleManifestExcel::SampleField::SangerTubeId.new.update(row: row).value).to eq(tube_column_list.find(:sanger_tube_id).value)       
  end

  it 'sanger tube id should match equivalent sample value' do
    row = build(:row, data: tube_column_list.column_values, columns: tube_column_list)
    expect(SampleManifestExcel::SampleField::SangerTubeId.new.update(row: row).match?(sample)).to be_falsey
    row = build(:row, data: tube_column_list.column_values(sanger_tube_id: sample.assets.first.sanger_human_barcode), columns: tube_column_list)
    expect(SampleManifestExcel::SampleField::SangerTubeId.new.update(row: row).match?(sample)).to be_truthy 
  end
end
