require 'rails_helper'

RSpec.describe SampleManifestExcel::SpecialisedFieldList, type: :model, sample_manifest_excel: true do

  let(:specialised_field_list) { SampleManifestExcel::SpecialisedFieldList.new }

  it 'loads all of the specialised fields' do
    expect(specialised_field_list.count).to eq(11)
  end

  it 'finds the correct field class' do
    expect(specialised_field_list.find(:donor_id)).to eq(SampleManifestExcel::SpecialisedField::DonorId)
    expect(specialised_field_list.find(:well)).to eq(SampleManifestExcel::SpecialisedField::Well)
  end

end
