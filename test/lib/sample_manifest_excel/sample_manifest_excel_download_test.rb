
require 'test_helper.rb'

class SampleManifestExcelDownloadTest < ActiveSupport::TestCase

  attr_reader :download, :spreadsheet, :sample_manifest

  def setup
    @sample_manifest = create(:sample_manifest_with_samples)
    @download = SampleManifestExcel::Download.new(sample_manifest)
    download.save('test.xlsx')
    @spreadsheet = Roo::Spreadsheet.open('test.xlsx')
  end

  test "should create an excel file"  do
    assert File.file?('test.xlsx')
  end

  test "should create a worksheet" do
    assert_equal "DNA Collections Form", spreadsheet.sheets.first
  end

  test "should add the title to the first worksheet" do
    assert_equal "DNA Collections Form", spreadsheet.sheet(0).cell(1,1)
  end

  test "should add study to the worksheet" do
    assert_equal "Study:", spreadsheet.sheet(0).cell(5,1)
    assert_equal sample_manifest.study.abbreviation, spreadsheet.sheet(0).cell(5,2)
  end

  test "should add supplier to worksheet" do
    assert_equal "Supplier:", spreadsheet.sheet(0).cell(6,1)
    assert_equal sample_manifest.supplier.name, spreadsheet.sheet(0).cell(6,2)
  end

  test "should add standard headings to worksheet" do
    download.columns.each_with_index do |column, i|
      assert_equal column.heading, spreadsheet.sheet(0).cell(9,i+1)
    end
  end

  def teardown
    File.delete('test.xlsx')
  end
  
end
