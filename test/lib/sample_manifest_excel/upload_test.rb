require "test_helper"

class UploadTest < ActiveSupport::TestCase

  context "Columns" do

    attr_reader :column_list, :dodgy_column

    setup do
      @column_list = build(:column_list)
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

    
  end
    
end