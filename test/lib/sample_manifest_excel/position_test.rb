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
    assert_equal "A1:D1", SampleManifestExcel::Position.new(first_column: 1, last_column: 4, first_row: 1).reference
    assert_equal "B2:F2", SampleManifestExcel::Position.new(first_column: 2, last_column: 6, first_row: 2).reference
    assert_equal "C150:AZ150", SampleManifestExcel::Position.new(first_column: 3, last_column: 52, first_row: 150).reference
  end

  test "should create the right reference for position with 2 rows" do
    assert_equal "A1:A15", SampleManifestExcel::Position.new(first_column: 1, first_row: 1, last_row: 15).reference
    assert_equal "B3:B8", SampleManifestExcel::Position.new(first_column: 2, first_row: 3, last_row: 8).reference
    assert_equal "BA4:BA150", SampleManifestExcel::Position.new(first_column: 53, first_row: 4, last_row: 150).reference
  end
end