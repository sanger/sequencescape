require "test_helper"

class UploadTest < ActiveSupport::TestCase

  attr_reader :column_list

  def setup
    @column_list = build(:column_list_with_sanger_sample_id)
  end

  context "Columns" do

    attr_reader :dodgy_column

    setup do
      @dodgy_column = build(:column)
    end

    should "be valid if all of the headings relate to a column" do
      heading_names = column_list.headings.reverse
      heading_names.shift
      columns = SampleManifestExcel::Upload::Columns.new(heading_names, column_list)
      assert_equal heading_names.length, columns.count
      (1..heading_names.length).each do |i|
        assert columns.find(i+1)
      end
      assert columns.valid?
    end

    should "should be invalid if any of the headings do not relate to a column" do
      heading_names = column_list.headings << dodgy_column.heading
      columns = SampleManifestExcel::Upload::Columns.new(heading_names, column_list)
      refute columns.valid?
      assert_match dodgy_column.heading, columns.errors.full_messages.to_s
    end
  end

  context "Row" do

    attr_reader :row, :columns, :sample

    setup do
      @columns = SampleManifestExcel::Upload::Columns.new(column_list.headings, column_list)
      @sample = create(:sample)
    end

    should "not be valid without a valid row number" do
      assert SampleManifestExcel::Upload::Row.new(1, column_list.column_values, columns).valid?
      refute SampleManifestExcel::Upload::Row.new(nil, column_list.column_values, columns).valid?
      refute SampleManifestExcel::Upload::Row.new("nil", column_list.column_values, columns).valid?
    end

    should "not be valid without some data" do
      refute SampleManifestExcel::Upload::Row.new(1, nil, columns).valid?
    end

    should "not be valid without some columns" do
      refute SampleManifestExcel::Upload::Row.new(1, column_list.column_values, nil).valid?
    end

    should "not be valid without an associated sample" do
    end
    
  end
    
end