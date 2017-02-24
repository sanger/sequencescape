require 'rails_helper'

RSpec.describe SampleManifestExcel::Attributes, type: :model, sample_manifest_excel: true do
  
  let(:sample) { build(:sample_with_well) }

  it 'sanger plate id column returns sanger human barcode' do
    expect(SampleManifestExcel::Attributes.find(:sanger_plate_id).value(sample)).to eq(sample.wells.first.plate.sanger_human_barcode) 
  end

  it 'well column returns well description' do
    expect(SampleManifestExcel::Attributes.find(:well).value(sample)).to eq(sample.wells.first.map.description) 
  end

  it 'sanger sample id column returns sanger sample id of sample' do
    expect(SampleManifestExcel::Attributes.find(:sanger_sample_id).value(sample)).to eq(sample.sanger_sample_id) 
  end

  it 'donor id column returns sanger sample id' do
    expect(SampleManifestExcel::Attributes.find(:donor_id).value(sample)).to eq(sample.sanger_sample_id) 
  end

  it 'donor id 2 column returns sanger sample id' do
    expect(SampleManifestExcel::Attributes.find(:donor_id_2).value(sample)).to eq(sample.sanger_sample_id) 
  end

  it 'sanger tube id column returns sanger human barcode' do
    expect(SampleManifestExcel::Attributes.find(:sanger_tube_id).value(sample)).to eq(sample.assets.first.sanger_human_barcode) 
  end

  it 'column which has other attribute returns nothing' do
    expect(SampleManifestExcel::Attributes.find(:no_attribute_here).value(sample)).to be_nil
  end
end
