require 'test_helper'

class ColumnListTest < ActiveSupport::TestCase

  attr_reader :column_list, :column_headings

  def setup
    @column_headings = ["heading_1", "heading_2", "heading_3", "heading_4", "heading_5"]
    @column_list = SampleManifestExcel::ColumnList.new(column_headings)
  end

  test "should create a list of columns" do
    assert_equal column_headings.length, column_list.count
  end

  test "#headings should return headings" do
    assert_equal column_headings, column_list.headings
  end

end