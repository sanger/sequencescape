require 'rails_helper'

RSpec.describe SampleManifestExcel::MultiplexedLibraryTubeField, type: :model, sample_manifest_excel: true do

  let(:column_list) { build(:column_list_for_multiplexed_library_tube) }
  let!(:library_type) { create(:library_type, name: column_list.find_by(:name, :library_type).value) }

  it 'will have the correct type' do
    expect(SampleManifestExcel::MultiplexedLibraryTubeField::LibraryType.new).to be_multiplexed_library_tube_field
  end

  it 'will have a list of subclasses' do
    expect(SampleManifestExcel::MultiplexedLibraryTubeField::Base.fields.count).to eq(SampleManifestExcel::MultiplexedLibraryTubeField::Base.subclasses.count) 
    expect(SampleManifestExcel::MultiplexedLibraryTubeField::Base.fields[:library_type]).to eq(SampleManifestExcel::MultiplexedLibraryTubeField::LibraryType) 
  end

  it 'will not be valid if library type is not in the row' do
    expect(SampleManifestExcel::MultiplexedLibraryTubeField::LibraryType.new.update(row: build(:row_for_plate, data: column_list.column_values, columns: column_list))).to be_valid
    expect(SampleManifestExcel::MultiplexedLibraryTubeField::LibraryType.new.update(row: build(:row_for_plate, data: column_list.column_values(library_type: nil), columns: column_list))).to_not be_valid
  end

  it 'will not be valid if library type does not exist' do
    expect(SampleManifestExcel::MultiplexedLibraryTubeField::LibraryType.new.update(row: build(:row_for_plate, data: column_list.column_values(library_type: build(:library_type)), columns: column_list))).to_not be_valid
  end

  it 'will not be valid if insert size from is not in the row' do
    expect(SampleManifestExcel::MultiplexedLibraryTubeField::InsertSizeFrom.new.update(row: build(:row_for_plate, data: column_list.column_values, columns: column_list))).to be_valid
    expect(SampleManifestExcel::MultiplexedLibraryTubeField::InsertSizeFrom.new.update(row: build(:row_for_plate, data: column_list.column_values(insert_size_from: nil), columns: column_list))).to_not be_valid
  end

  it 'will not be valid if insert size from is not a number greater than zero' do
    expect(SampleManifestExcel::MultiplexedLibraryTubeField::InsertSizeFrom.new.update(row: build(:row_for_plate, data: column_list.column_values(insert_size_from: 0), columns: column_list))).to_not be_valid
    expect(SampleManifestExcel::MultiplexedLibraryTubeField::InsertSizeFrom.new.update(row: build(:row_for_plate, data: column_list.column_values(insert_size_from: 'zero'), columns: column_list))).to_not be_valid
  end

  it 'will not be valid if insert size to is not in the row' do
    expect(SampleManifestExcel::MultiplexedLibraryTubeField::InsertSizeTo.new.update(row: build(:row_for_plate, data: column_list.column_values, columns: column_list))).to be_valid
    expect(SampleManifestExcel::MultiplexedLibraryTubeField::InsertSizeTo.new.update(row: build(:row_for_plate, data: column_list.column_values(insert_size_to: nil), columns: column_list))).to_not be_valid
  end

  it 'will not be valid if insert size to is not a number greater than zero' do
    expect(SampleManifestExcel::MultiplexedLibraryTubeField::InsertSizeTo.new.update(row: build(:row_for_plate, data: column_list.column_values(insert_size_to: 0), columns: column_list))).to_not be_valid
    expect(SampleManifestExcel::MultiplexedLibraryTubeField::InsertSizeTo.new.update(row: build(:row_for_plate, data: column_list.column_values(insert_size_to: 'zero'), columns: column_list))).to_not be_valid
  end

end
