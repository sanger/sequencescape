require 'test_helper'

class WorksheetTest < ActiveSupport::TestCase

	context "data worksheet" do

		attr_reader :xls, :worksheet, :axlsx_worksheet, :sample_manifest, :column_list, :spreadsheet

		setup do
			@xls = Axlsx::Package.new
	    @axlsx_worksheet = xls.workbook.add_worksheet(name: 'Data worksheet')
	    @sample_manifest = create(:sample_manifest_with_samples)
	    @column_list = SampleManifestExcel::ColumnList.new(YAML::load_file(File.expand_path(File.join(Rails.root,"test","data", "sample_manifest_excel","sample_manifest_columns_basic_plate.yml"))))
	    @range_list = SampleManifestExcel::RangeList.new(YAML::load_file(File.expand_path(File.join(Rails.root,"test","data", "sample_manifest_excel","sample_manifest_validation_ranges.yml"))))
	    @worksheet = SampleManifestExcel::Worksheet.new axlsx_worksheet: axlsx_worksheet, columns: column_list
	  end

		should "should have a axlsx worksheet" do
	  	assert worksheet.axlsx_worksheet
	  end

	  should "should add title and info" do
	  	worksheet.add_title_and_info(sample_manifest)
	  	save_file
	    assert_equal "DNA Collections Form", spreadsheet.sheet(0).cell(1,1)
	    assert_equal "Study:", spreadsheet.sheet(0).cell(5,1)
	    assert_equal sample_manifest.study.abbreviation, spreadsheet.sheet(0).cell(5,2)
	    assert_equal "Supplier:", spreadsheet.sheet(0).cell(6,1)
	    assert_equal sample_manifest.supplier.name, spreadsheet.sheet(0).cell(6,2)
	    assert_equal "No. Plates Sent:", spreadsheet.sheet(0).cell(7,1)
    	assert_equal sample_manifest.count.to_s, spreadsheet.sheet(0).cell(7,2)
	  end

	  # should "prepare columns" do
	  # 	worksheet.prepare_columns(ranges, styles)
	  # end
	end

	context "validations ranges worksheet" do

	  attr_reader :range_worksheet, :axlsx_worksheet, :range_list

	  setup do
	    @xls = Axlsx::Package.new
		  @axlsx_worksheet = xls.workbook.add_worksheet(name: 'Ranges')
		  @range_list = SampleManifestExcel::RangeList.new(YAML::load_file(File.expand_path(File.join(Rails.root,"test","data", "sample_manifest_excel","sample_manifest_validation_ranges.yml"))))
	    @range_worksheet = SampleManifestExcel::Worksheet.new(axlsx_worksheet: axlsx_worksheet, range_list: range_list)
	  end

	  should "should have a axlsx worksheet" do
	  	assert range_worksheet.axlsx_worksheet
	  end

	  should "add ranges to axlsx worksheet" do
	  	range_worksheet.add_ranges
	  	save_file
	  	range = range_worksheet.ranges.first.last
	  	range.options.each_with_index do |option, i|
	  		assert_equal option, spreadsheet.sheet(0).cell(1,i+1)
	  	end
	  	assert_equal range_worksheet.ranges.count, axlsx_worksheet.rows.count
	  end
	end

	def save_file
	  xls.serialize('test.xlsx')
	  @spreadsheet = Roo::Spreadsheet.open('test.xlsx')
	end

	def teardown
    File.delete('test.xlsx') if File.exists?('test.xlsx')
  end

end