require 'test_helper'

class RangeTest < ActiveSupport::TestCase

  attr_reader :range

  def setup
    @range = SampleManifestExcel::Range.new("yes_no")
  end

  test "should have name" do
  	assert range.name
  end

  test "should have a list of options" do
  	assert_equal [], range.list_of_options
  	options = ['yes', 'no']
  	range.list_of_options = options
  	assert_equal options, range.list_of_options
  end

  test "should have a position" do
  	assert_equal 0, range.position
  	range.position = 1
  	assert_equal 1, range.position
  end

  test "should have range of cells" do
  	range.position = 1
  	range.list_of_options = ['yes', 'no']
  	range.add_range_of_cells
  	assert_equal "A1:B1", range.range_of_cells
  end

  test "#set_position should set correct position to a range" do
    assert_equal 1, range.set_position(1).position
  end

end