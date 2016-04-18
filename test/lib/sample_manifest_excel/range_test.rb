require 'test_helper'

class RangeTest < ActiveSupport::TestCase

  attr_reader :range

  def setup
    @range = SampleManifestExcel::Range.new(['option1', 'option2', 'option3'], 1)
  end

  test "should have options" do
  	assert_equal ['option1', 'option2', 'option3'], range.options
  end

  test "should have row number" do
    assert_equal 1, range.row
  end

  test "should have a range" do
  	assert_equal SampleManifestExcel::Position.new(first_column: 1, last_column: 3, first_row: 1).range, range.range
  end

end