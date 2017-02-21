require 'test_helper'

class SampleFieldTest < ActiveSupport::TestCase
  attr_reader :plate_column_list, :tube_column_list, :sample

  def setup
    @plate_column_list = build(:column_list_for_plate)
    @tube_column_list = build(:column_list_for_tube)
    @sample = create(:sample_with_well)
  end

  test 'should be a sample field' do
    assert SampleManifestExcel::SampleField::SangerPlateId.new.sample_field?
  end

  test 'should have a list of subclasses' do
    assert_equal SampleManifestExcel::SampleField::Base.subclasses.count, SampleManifestExcel::SampleField::Base.fields.count
    assert_equal SampleManifestExcel::SampleField::SangerPlateId, SampleManifestExcel::SampleField::Base.fields[:sanger_plate_id]
  end

  test 'sanger plate id should return correct value' do
    row = build(:row, data: plate_column_list.column_values, columns: plate_column_list)
    assert_equal plate_column_list.find(:sanger_plate_id).value,
                  SampleManifestExcel::SampleField::SangerPlateId.new.update(row: row).value
  end

  test 'sanger plate id should match equivalent sample value' do
    row = build(:row, data: plate_column_list.column_values, columns: plate_column_list)
    refute SampleManifestExcel::SampleField::SangerPlateId.new.update(row: row).match?(sample)
    row = build(:row, data: plate_column_list.column_values(sanger_plate_id: sample.wells.first.plate.sanger_human_barcode), columns: plate_column_list)
    assert SampleManifestExcel::SampleField::SangerPlateId.new.update(row: row).match?(sample)
  end

  test 'well should return correct value' do
    row = build(:row, data: plate_column_list.column_values, columns: plate_column_list)
    assert_equal plate_column_list.find(:well).value,
                  SampleManifestExcel::SampleField::Well.new.update(row: row).value
  end

  test 'well should match equivalent sample value' do
    row = build(:row, data: plate_column_list.column_values, columns: plate_column_list)
    refute SampleManifestExcel::SampleField::Well.new.update(row: row).match?(sample)
    row = build(:row, data: plate_column_list.column_values(well: sample.wells.first.map.description), columns: plate_column_list)
    assert SampleManifestExcel::SampleField::Well.new.update(row: row).match?(sample)
  end

  test 'sanger sample id should return correct value' do
    row = build(:row, data: plate_column_list.column_values, columns: plate_column_list)
    assert_equal plate_column_list.find(:sanger_sample_id).value,
                  SampleManifestExcel::SampleField::SangerSampleId.new.update(row: row).value
  end

  test 'sanger sample id should match equivalent sample value' do
    row = build(:row, data: plate_column_list.column_values, columns: plate_column_list)
    refute SampleManifestExcel::SampleField::SangerSampleId.new.update(row: row).match?(sample)
    row = build(:row, data: plate_column_list.column_values(sanger_sample_id: sample.sanger_sample_id), columns: plate_column_list)
    assert SampleManifestExcel::SampleField::SangerSampleId.new.update(row: row).match?(sample)
  end

  test 'donor id should return correct value' do
    row = build(:row, data: plate_column_list.column_values, columns: plate_column_list)
    assert_equal plate_column_list.find(:donor_id).value,
                  SampleManifestExcel::SampleField::DonorId.new.update(row: row).value
  end

  test 'donor id should match equivalent sample value' do
    row = build(:row, data: plate_column_list.column_values, columns: plate_column_list)
    refute SampleManifestExcel::SampleField::DonorId.new.update(row: row).match?(sample)
    row = build(:row, data: plate_column_list.column_values(donor_id: sample.sanger_sample_id), columns: plate_column_list)
    assert SampleManifestExcel::SampleField::DonorId.new.update(row: row).match?(sample)
  end

  test 'donor id 2 should return correct value' do
    row = build(:row, data: tube_column_list.column_values, columns: tube_column_list)
    assert_equal tube_column_list.find(:donor_id2).value,
                  SampleManifestExcel::SampleField::DonorId2.new.update(row: row).value
  end

  test 'donor id 2 should match equivalent sample value' do
    row = build(:row, data: tube_column_list.column_values, columns: tube_column_list)
    refute SampleManifestExcel::SampleField::DonorId2.new.update(row: row).match?(sample)
    row = build(:row, data: tube_column_list.column_values(donor_id2: sample.sanger_sample_id), columns: tube_column_list)
    assert SampleManifestExcel::SampleField::DonorId2.new.update(row: row).match?(sample)
  end

  test 'sanger tube id should return correct value' do
    row = build(:row, data: tube_column_list.column_values, columns: tube_column_list)
    assert_equal tube_column_list.find(:sanger_tube_id).value,
                  SampleManifestExcel::SampleField::SangerTubeId.new.update(row: row).value
  end

  test 'sanger tube id should match equivalent sample value' do
    row = build(:row, data: tube_column_list.column_values, columns: tube_column_list)
    refute SampleManifestExcel::SampleField::SangerTubeId.new.update(row: row).match?(sample)
    row = build(:row, data: tube_column_list.column_values(sanger_tube_id: sample.assets.first.sanger_human_barcode), columns: tube_column_list)
    assert SampleManifestExcel::SampleField::SangerTubeId.new.update(row: row).match?(sample)
  end
end
