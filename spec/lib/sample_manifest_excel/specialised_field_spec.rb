require 'rails_helper'

RSpec.describe SampleManifestExcel::SpecialisedField, type: :model, sample_manifest_excel: true do

  class MySecretField
    include SampleManifestExcel::SpecialisedField
  end

  let(:column) { build(:column, name: :my_secret_field, heading: 'My Secret Field', value: 'My Secret Value') }
  let(:column_list) { build(:column_list).add_with_number(column) }
  let(:row) { build(:row, data: column_list.column_values, columns: column_list) }

  it 'has a type' do
    expect(MySecretField.new.type).to eq(:my_secret_field) 
  end

  it 'should update value from row' do
    field = MySecretField.new.update(row: row)
    expect(field.value_present?).to be_truthy 
    expect(field.value).to eq('My Secret Value') 
  end
end
