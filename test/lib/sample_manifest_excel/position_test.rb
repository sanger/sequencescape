require 'test_helper'

class PositionTest < ActiveSupport::TestCase

  attr_reader :position

  test "should have correct attributes" do
    position = SampleManifestExcel::Position.new(first_column: 1, last_column: 4, first_row: 2, last_row: 3)
    assert_equal 1, position.first_column
    assert_equal 4, position.last_column
    assert_equal 2, position.first_row
    assert_equal 3, position.last_row 
  end

  test "should create the right reference for position with 2 columns" do
    assert_equal "$A$1:$D$1", SampleManifestExcel::Position.new(first_column: 1, last_column: 4, first_row: 1).reference
    assert_equal "$B$2:$F$2", SampleManifestExcel::Position.new(first_column: 2, last_column: 6, first_row: 2).reference
    assert_equal "$C$150:$AZ$150", SampleManifestExcel::Position.new(first_column: 3, last_column: 52, first_row: 150).reference
  end

  test "should create the right reference for position with 2 rows" do
    assert_equal "$A$1:$A$15", SampleManifestExcel::Position.new(first_column: 1, first_row: 1, last_row: 15).reference
    assert_equal "$B$3:$B$8", SampleManifestExcel::Position.new(first_column: 2, first_row: 3, last_row: 8).reference
    assert_equal "$BA$4:$BA$150", SampleManifestExcel::Position.new(first_column: 53, first_row: 4, last_row: 150).reference
  end

  test "should create the right first cell relative reference" do
    assert_equal "A1", SampleManifestExcel::Position.new(first_column: 1, first_row: 1, last_row: 15).first_cell_relative_reference
    assert_equal "B3", SampleManifestExcel::Position.new(first_column: 2, first_row: 3, last_row: 8).first_cell_relative_reference
    assert_equal "BA4", SampleManifestExcel::Position.new(first_column: 53, first_row: 4, last_row: 150).first_cell_relative_reference
  end
end