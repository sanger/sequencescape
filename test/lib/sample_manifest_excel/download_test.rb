
require 'test_helper.rb'

class DownloadTest < ActiveSupport::TestCase

  attr_reader :download, :spreadsheet, :sample_manifest, :column_list, :range_list

  def setup
    @sample_manifest = create(:sample_manifest_with_samples)
    @column_list = SampleManifestExcel::ColumnList.new(YAML::load_file(File.expand_path(File.join(Rails.root,"test","data", "sample_manifest_excel","sample_manifest_columns_basic_plate.yml"))))
    @range_list = SampleManifestExcel::RangeList.new(YAML::load_file(File.expand_path(File.join(Rails.root,"test","data", "sample_manifest_excel","sample_manifest_validation_ranges.yml"))))
    @download = SampleManifestExcel::Download.new(sample_manifest, column_list, range_list)
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

  def teardown
    File.delete('test.xlsx') if File.exists?('test.xlsx')
  end

end
