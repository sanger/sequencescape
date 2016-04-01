
require 'test_helper.rb'

class DownloadTest < ActiveSupport::TestCase

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

  test "should have a type" do
    assert_equal sample_manifest.asset_type, download.type
  end

  test "should add all of the samples" do
    assert_equal sample_manifest.samples.count+9, spreadsheet.sheet(0).last_row
  end

  test "should add the attributes for each sample" do
    sample = sample_manifest.samples.first
    assert_equal sample.wells.first.plate.sanger_human_barcode, spreadsheet.sheet(0).cell(10,1)
    assert_equal sample.wells.first.map.description, spreadsheet.sheet(0).cell(10,2)
    assert_equal sample.sanger_sample_id, spreadsheet.sheet(0).cell(10,3)
    assert_equal sample.sanger_sample_id, spreadsheet.sheet(0).cell(10,18)


    sample = sample_manifest.samples.last
    assert_equal sample.wells.first.plate.sanger_human_barcode, spreadsheet.sheet(0).cell(9+sample_manifest.samples.count,1)
    assert_equal sample.wells.first.map.description, spreadsheet.sheet(0).cell(9+sample_manifest.samples.count,2)
    assert_equal sample.sanger_sample_id, spreadsheet.sheet(0).cell(9+sample_manifest.samples.count,3)
    assert_equal sample.sanger_sample_id, spreadsheet.sheet(0).cell(9+sample_manifest.samples.count,18)

  end

  def teardown
    File.delete('test.xlsx')
  end
  
end
