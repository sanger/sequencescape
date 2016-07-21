
require_relative '../../test_helper.rb'

class DownloadTest < ActiveSupport::TestCase

  attr_reader :sample_manifest, :download, :spreadsheet

  def setup

    SampleManifestExcel.configure do |config|
      config.folder = File.join("test","data", "sample_manifest_excel")
      config.load!
    end

  end

  context "Plate download" do

    setup do
      @sample_manifest = create(:sample_manifest_with_samples)
      @download = SampleManifestExcel::Download.new(sample_manifest, 
        SampleManifestExcel.configuration.columns.plate_full.dup, SampleManifestExcel.configuration.ranges.dup)
      save_file
    end

    should "create an excel file" do
      assert File.file?('test.xlsx')
    end

    should "create the two different types of worksheet" do
      assert_equal "DNA Collections Form", spreadsheet.sheets.first
      assert_equal "Ranges", spreadsheet.sheets.last
    end

    should "have the correct number of columns" do
      assert_equal SampleManifestExcel.configuration.columns.plate_full.count, download.column_list.count
    end
  end

  context "Tube download" do

    setup do
      @sample_manifest = create(:tube_sample_manifest_with_samples)
      @download = SampleManifestExcel::Download.new(sample_manifest, 
        SampleManifestExcel.configuration.columns.tube_full.dup, SampleManifestExcel.configuration.ranges.dup)
      save_file
    end

    should "create an excel file" do
      assert File.file?('test.xlsx')
    end

    should "create the two different types of worksheet" do
      assert_equal "DNA Collections Form", spreadsheet.sheets.first
      assert_equal "Ranges", spreadsheet.sheets.last
    end

    should "have the correct number of columns" do
      assert_equal SampleManifestExcel.configuration.columns.tube_full.count, download.column_list.count
    end
  end

  def save_file
    download.save('test.xlsx')
    @spreadsheet = Roo::Spreadsheet.open('test.xlsx')
  end

  def teardown
    File.delete('test.xlsx') if File.exists?('test.xlsx')
    SampleManifestExcel.reset!
  end

end
