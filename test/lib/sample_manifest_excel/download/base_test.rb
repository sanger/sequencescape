
require 'test_helper.rb'

class BaseTest < ActiveSupport::TestCase

  attr_reader :download, :spreadsheet, :sample_manifest, :column_list, :range_list

  def setup
    @sample_manifest = create(:sample_manifest_with_samples)
    @column_list = SampleManifestExcel::ColumnList.new(YAML::load_file(File.expand_path(File.join(Rails.root,"test","data", "sample_manifest_excel","sample_manifest_columns_basic_plate.yml"))))
    @range_list = SampleManifestExcel::RangeList.new(YAML::load_file(File.expand_path(File.join(Rails.root,"test","data", "sample_manifest_excel","sample_manifest_validation_ranges.yml"))))
    @download = SampleManifestExcel::Download::Base.new(sample_manifest, column_list, range_list)
    download.save('test.xlsx')
    @spreadsheet = Roo::Spreadsheet.open('test.xlsx')
  end

  test "should create an excel file"  do
    assert File.file?('test.xlsx')
  end

  test "should create a axlsx data worksheet and axlsx ranges worksheet" do
    assert_equal "DNA Collections Form", spreadsheet.sheets.first
    assert_equal "Ranges", spreadsheet.sheets.last
  end

  test "should add the title to the first worksheet" do
    assert_equal "DNA Collections Form", spreadsheet.sheet(0).cell(1,1)
  end

  test "should have a data worksheet and ranges worksheet" do
    assert_instance_of SampleManifestExcel::Worksheet, download.data_worksheet
    assert_instance_of SampleManifestExcel::Worksheet, download.ranges_worksheet
  end

  test "should have styles" do
    assert_equal 5, download.styles.count
  end

  test "should know the columns names specific to the download type" do
    assert_equal [:sanger_plate_id, :well], download.columns_names
  end

  test "column list should be extracted from full column list based on required columns names" do
    assert_equal 2, download.column_list.count
    assert_instance_of SampleManifestExcel::ColumnList, download.column_list
  end

  def teardown
    File.delete('test.xlsx') if File.exists?('test.xlsx')
  end

end
