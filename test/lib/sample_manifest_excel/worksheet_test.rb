require 'test_helper'

class WorksheetTest < ActiveSupport::TestCase

	context "data worksheet" do

		attr_reader :xls, :worksheet, :axlsx_worksheet, :sample_manifest, :column_list, :spreadsheet, :styles, :workbook, :ranges_worksheet

		setup do
			@xls = Axlsx::Package.new
			@workbook = xls.workbook
	    @axlsx_worksheet = workbook.add_worksheet(name: 'Data worksheet')
	    @axlsx_ranges_worksheet = workbook.add_worksheet(name: 'Ranges')
	    @range_list = SampleManifestExcel::RangeList.new(YAML::load_file(File.expand_path(File.join(Rails.root,"test","data", "sample_manifest_excel","sample_manifest_validation_ranges.yml"))))
	    @ranges_worksheet = SampleManifestExcel::Worksheet.new(axlsx_worksheet: @axlsx_ranges_worksheet, ranges: range_list)
	    range_list.set_absolute_references(ranges_worksheet)
	    @sample_manifest = create(:sample_manifest_with_samples)
	    @column_list = SampleManifestExcel::ColumnList.new(YAML::load_file(File.expand_path(File.join(Rails.root,"test","data", "sample_manifest_excel","sample_manifest_columns_basic_plate.yml"))))
	    style = SampleManifestExcel::Style.new(workbook, {locked: false})
    	@styles = {unlock: style, style_name: style, wrong_value: style, empty_cell: style, wrap_text: style}
	    @worksheet = SampleManifestExcel::Worksheet.new axlsx_worksheet: axlsx_worksheet, columns: column_list, sample_manifest: sample_manifest, styles: styles, ranges: range_list, password: '1111'
	  	xls.serialize('test.xlsx')
	  	@spreadsheet = Roo::Spreadsheet.open('test.xlsx')
	  end

		should "should have a axlsx worksheet" do
	  	assert worksheet.axlsx_worksheet
	  end

	  should "should add title and info" do
	    assert_equal "DNA Collections Form", spreadsheet.sheet(0).cell(1,1)
	    assert_equal "Study:", spreadsheet.sheet(0).cell(5,1)
	    assert_equal sample_manifest.study.abbreviation, spreadsheet.sheet(0).cell(5,2)
	    assert_equal "Supplier:", spreadsheet.sheet(0).cell(6,1)
	    assert_equal sample_manifest.supplier.name, spreadsheet.sheet(0).cell(6,2)
	    assert_equal "No. Plates Sent:", spreadsheet.sheet(0).cell(7,1)
    	assert_equal sample_manifest.count.to_s, spreadsheet.sheet(0).cell(7,2)
	  end

	  should "add standard headings to worksheet" do
	    worksheet.columns.headings.each_with_index do |heading, i|
	      assert_equal heading, spreadsheet.sheet(0).cell(9,i+1)
	    end
	  end

	  should "prepare columns" do
	  	worksheet.columns.each do |k, column|
	  		assert column.position
	  	end
	  	worksheet.columns.with_unlocked.all? {|column| column.unlocked.is_a? Integer}
	  end

	  should "should add all of the samples" do
	    assert_equal sample_manifest.samples.count+9, spreadsheet.sheet(0).last_row
	  end

	  should "should add the attributes for each sample" do
	    [sample_manifest.samples.first, sample_manifest.samples.last].each do |sample|
	      worksheet.columns.with_attributes.each do |column|
	        assert_equal column.attribute_value(sample), spreadsheet.sheet(0).cell(sample_manifest.samples.index(sample)+10, column.number)
	      end
	    end
	  end

	  should "add the data validations" do
	    assert_equal column_list.with_validations.count, worksheet.axlsx_worksheet.send(:data_validations).count
	    column = column_list.with_validations.first
	    assert_equal column.reference, worksheet.axlsx_worksheet.send(:data_validations).first.sqref
	    column = column_list.with_validations.last
	    assert_equal column.reference, worksheet.axlsx_worksheet.send(:data_validations).last.sqref
	    assert worksheet.axlsx_worksheet.send(:data_validations).find {|validation| validation.formula1 == column_list.find_by(:gender).validation.options[:formula1]}
	  end

	  should "set right formula 1 to validations" do
	    range = range_list.find_by(:gender)
	    assert worksheet.axlsx_worksheet.send(:data_validations).find {|validation| validation.formula1 == range.absolute_reference}
	  end

	  should "add conditional formatting to unlocked columns" do
	    assert_equal column_list.with_unlocked.count, worksheet.axlsx_worksheet.send(:conditional_formattings).count {|cf| cf.rules.find {|rule| rule.formula.first == 'FALSE'}}
	    column = column_list.with_unlocked.first
	    assert_equal column.reference, worksheet.axlsx_worksheet.send(:conditional_formattings).first.sqref
	    column = column_list.with_unlocked.last
	    assert_equal column.reference, worksheet.axlsx_worksheet.send(:conditional_formattings).select {|cf| cf.rules.first.formula.first == 'FALSE'}.last.sqref
	  end

	  should "add all required conditional formatting to all columns" do
	    assert_equal 32, worksheet.axlsx_worksheet.send(:conditional_formattings).count
	    column = column_list.find_by(:supplier_sample_name)
	    assert worksheet.axlsx_worksheet.send(:conditional_formattings).any? {|cf| cf.sqref == column.reference}
	    cf = worksheet.axlsx_worksheet.send(:conditional_formattings).select {|cf| cf.sqref == column.reference}
	    assert_equal column.cf_options.count, cf.last.rules.count
	    assert_equal column.cf_options.last['formula'], cf.last.rules.last.formula.first
	  end

	  should "panes should be frozen correctly" do
	    assert_equal worksheet.freeze_after_column(:sanger_sample_id).number, worksheet.axlsx_worksheet.sheet_view.pane.x_split
	    assert_equal worksheet.first_row-1, worksheet.axlsx_worksheet.sheet_view.pane.y_split
	    assert_equal "frozen", worksheet.axlsx_worksheet.sheet_view.pane.state
	  end

	  should "worksheet should be protected with password but columns and rows format can be changed" do
	    assert worksheet.axlsx_worksheet.sheet_protection.password
	    refute worksheet.axlsx_worksheet.sheet_protection.format_columns
	    refute worksheet.axlsx_worksheet.sheet_protection.format_rows
	  end

	end

	context "validations ranges worksheet" do

	  attr_reader :range_worksheet, :axlsx_worksheet, :range_list, :spreadsheet

	  setup do
	    @xls = Axlsx::Package.new
		  @axlsx_worksheet = xls.workbook.add_worksheet(name: 'Ranges')
		  @range_list = SampleManifestExcel::RangeList.new(YAML::load_file(File.expand_path(File.join(Rails.root,"test","data", "sample_manifest_excel","sample_manifest_validation_ranges.yml"))))
	    @range_worksheet = SampleManifestExcel::Worksheet.new(axlsx_worksheet: axlsx_worksheet, ranges: range_list)
	 	  @xls.serialize('test.xlsx')
	  	@spreadsheet = Roo::Spreadsheet.open('test.xlsx')
	  end

	  should "should have a axlsx worksheet" do
	  	assert range_worksheet.axlsx_worksheet
	  end

	  should "add ranges to axlsx worksheet" do
	  	range = range_worksheet.ranges.first.last
	  	range.options.each_with_index do |option, i|
	  		assert_equal option, spreadsheet.sheet(0).cell(1,i+1)
	  	end
	  	assert_equal range_worksheet.ranges.count, axlsx_worksheet.rows.count
	  end
	end

	def teardown
    File.delete('test.xlsx') if File.exists?('test.xlsx')
  end

end