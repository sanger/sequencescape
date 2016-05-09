
require 'test_helper.rb'

class FullTest < ActiveSupport::TestCase

	attr_reader :download, :spreadsheet, :sample_manifest, :column_list, :range_list

  def setup
    @sample_manifest = create(:sample_manifest_with_samples)
    @column_list = SampleManifestExcel::ColumnList.new(YAML::load_file(File.expand_path(File.join(Rails.root,"test","data", "sample_manifest_excel","sample_manifest_all_columns.yml"))))
    @range_list = SampleManifestExcel::RangeList.new(YAML::load_file(File.expand_path(File.join(Rails.root,"test","data", "sample_manifest_excel","sample_manifest_validation_ranges.yml"))))
    @download = SampleManifestExcel::Download::Full.new(sample_manifest, column_list, range_list)
    download.save('test.xlsx')
    @spreadsheet = Roo::Spreadsheet.open('test.xlsx')
  end

  test "should have correct columns_names" do
  	assert_equal 51, download.columns_names.count
  end

  def teardown
    File.delete('test.xlsx') if File.exists?('test.xlsx')
  end

end