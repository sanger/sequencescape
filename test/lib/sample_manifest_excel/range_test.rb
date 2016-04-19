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
  	assert_equal SampleManifestExcel::Position.new(first_column: 1, last_column: 3, first_row: 1).reference, range.reference
  end

  test "#set_absolute_reference should set full reference" do
    worksheet = Axlsx::Package.new.workbook.add_worksheet name: 'New worksheet'
    range.set_absolute_reference(worksheet)
    assert_equal "#{worksheet.name}!#{range.reference}", range.absolute_reference
  end

end