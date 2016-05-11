require 'test_helper'

class RangeTest < ActiveSupport::TestCase

  attr_reader :range

  def setup
    @range = build :range
  end

  test "should have options" do
  	assert_equal ['option1', 'option2', 'option3'], range.options
  end

  test "should have row number" do
    assert_equal 1, range.row
  end

  test "should have a range" do
  	assert_equal SampleManifestExcel::Position.new(first_column: 1, last_column: 3, first_row: 1).reference, range.reference
  end

  test "#set_absolute_reference should set full reference" do
    range.set_absolute_reference('Ranges')
    assert_equal "Ranges!#{range.reference}", range.absolute_reference
  end

  test "should not be valid without row" do
    range = SampleManifestExcel::Range.new([1,2,3], nil)
    refute range.valid?
  end

end