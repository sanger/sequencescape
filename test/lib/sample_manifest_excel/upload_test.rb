require "test_helper"

class UploadTest < ActiveSupport::TestCase

  context "Headings" do

    attr_reader :column_list, :dodgy_column

    setup do
      @column_list = build(:column_list)
      @dodgy_column = build(:column)
    end

    should "be valid if all of the headings relate to a column" do
      heading_names = column_list.headings.reverse
      heading_names.shift
      headings = SampleManifestExcel::Upload::Headings.new(heading_names, column_list)
      assert_equal heading_names.length, headings.count
      (1..heading_names.length).each do |i|
        assert headings.find(i)
      end
    end

    should "should be invalid if any of the headings do not relate to a column" do
    end
  end
    
end