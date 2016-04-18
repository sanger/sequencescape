require 'test_helper'

class ValidationRangeWorksheet < ActiveSupport::TestCase

  attr_reader :range_worksheet, :axlsx_worksheet, :rangeList
  
  def setup
    @rangeList = SampleManifestExcel::RangeList.new(YAML::load_file(File.expand_path(File.join(Rails.root,"test","data", "sample_manifest_excel","sample_manifest_validation_ranges_short.yml"))))
    @axlsx_worksheet = Axlsx::Workbook.new.add_worksheet(name: 'Ranges')
    @range_worksheet = SampleManifestExcel::ValidationRangeWorksheet.new(rangeList, axlsx_worksheet)
  end

  test "should have a axlsx worksheet" do
  	assert range_worksheet.axlsx_worksheet
  end

  test "ranges should be added to axlsx worksheet" do
  	range = range_worksheet.rangeList.ranges.values.first
  	range.options.each_with_index do |option, i|
  		assert_equal option, axlsx_worksheet.rows.first.cells[i].value
  	end
  	assert_equal range_worksheet.rangeList.count, axlsx_worksheet.rows.count
  end

end