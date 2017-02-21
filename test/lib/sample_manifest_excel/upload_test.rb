require 'test_helper'

class UploadTest < ActiveSupport::TestCase
  attr_reader :column_list

  def setup
    @column_list = build(:column_list_for_plate)
  end

  test 'should be valid if all of the headings relate to a column' do
    heading_names = column_list.headings.reverse
    heading_names.pop
    upload = SampleManifestExcel::Upload.new(heading_names, column_list)
    assert_equal heading_names.length, upload.columns.count
    assert upload.valid?
  end

  test 'should be invalid if any of the headings do not relate to a column' do
    dodgy_column = build(:column)
    heading_names = column_list.headings << dodgy_column.heading
    upload = SampleManifestExcel::Upload.new(heading_names, column_list)
    refute upload.valid?
    assert_match dodgy_column.heading, upload.errors.full_messages.to_s
  end

  test 'should be invalid if there is no sanger sample id column' do
    column_list = build(:column_list)
    upload = SampleManifestExcel::Upload.new(column_list.headings, column_list)
    refute upload.valid?
  end

  context 'Row' do
    attr_reader :row, :sample, :valid_values

    setup do
      @sample = create(:sample_with_well)
      @valid_values = column_list.column_values(
                        sanger_sample_id: sample.id,
                        sanger_plate_id: sample.wells.first.plate.sanger_human_barcode,
                        well: sample.wells.first.map.description
                        )
    end

    should '#value should return value for specified key' do
      assert_equal sample.id, SampleManifestExcel::Upload::SampleRow.new(1, valid_values, column_list).value(:sanger_sample_id)
    end

    should '#at should return value at specified index (offset by 1)' do
      assert_equal sample.id, SampleManifestExcel::Upload::SampleRow.new(1, valid_values, column_list).at(column_list.find_by(:name, :sanger_sample_id).number)
    end

    should '#first? should be true if this is the first row' do
      SampleManifestExcel::Upload::SampleRow.new(1, valid_values, column_list).first?
    end

    should 'not be valid without a valid row number' do
      assert SampleManifestExcel::Upload::SampleRow.new(1, valid_values, column_list).valid?
      refute SampleManifestExcel::Upload::SampleRow.new(nil, valid_values, column_list).valid?
      refute SampleManifestExcel::Upload::SampleRow.new('nil', valid_values, column_list).valid?
    end

    should 'not be valid without some data' do
      refute SampleManifestExcel::Upload::SampleRow.new(1, nil, column_list).valid?
    end

    should 'not be valid without some columns' do
      refute SampleManifestExcel::Upload::SampleRow.new(1, valid_values, nil).valid?
    end

    should 'not be valid without an associated sample' do
      column_list = build(:column_list_for_plate)
      refute SampleManifestExcel::Upload::SampleRow.new(1, column_list.column_values, column_list).valid?
    end

    should 'not be valid unless the sample has a primary receptacle' do
      refute SampleManifestExcel::Upload::SampleRow.new(1, column_list.column_values(
                                                  sanger_sample_id: create(:sample).id
                                                  ), column_list).valid?
    end

    context 'sample container' do
      should 'for plate should only be valid if barcode and location match' do
        column_list = build(:column_list_for_plate)
        valid_values = column_list.column_values(sanger_sample_id: sample.id, sanger_plate_id: sample.wells.first.plate.sanger_human_barcode)
        refute SampleManifestExcel::Upload::SampleRow.new(1, valid_values, column_list).valid?

        column_list = build(:column_list_for_plate)
        valid_values = column_list.column_values(sanger_sample_id: sample.id, well: sample.wells.first.map.description)
        refute SampleManifestExcel::Upload::SampleRow.new(1, valid_values, column_list).valid?
      end

      should 'for tube should only be valid if barcodes match' do
        tube = create(:sample_tube)
        column_list = build(:column_list_for_tube)
        valid_values = column_list.column_values(sanger_sample_id: tube.sample.id, sanger_tube_id: tube.sample.assets.first.sanger_human_barcode)
        assert SampleManifestExcel::Upload::SampleRow.new(1, valid_values, column_list).valid?

        column_list = build(:column_list_for_tube)
        valid_values = column_list.column_values(sanger_sample_id: tube.sample.id)
        refute SampleManifestExcel::Upload::SampleRow.new(1, valid_values, column_list).valid?
      end
    end
  end
end
