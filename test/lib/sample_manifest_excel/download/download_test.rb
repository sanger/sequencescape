
require 'test_helper.rb'

class DownloadTest < ActiveSupport::TestCase

  attr_reader :download, :spreadsheet, :sample_manifest, :column_list, :range_list, :styles

  context "Base download" do

    setup do
      @download = SampleManifestExcel::Download::Base.new(sample_manifest, column_list, range_list, styles)
      save_file
    end

    should "should create an excel file"  do
      assert File.file?('test.xlsx')
    end

    should "should have a axlsx data worksheet and axlsx ranges worksheet" do
      assert_equal "DNA Collections Form", spreadsheet.sheets.first
      assert_equal "Ranges", spreadsheet.sheets.last
    end

    should "should add the title to the first worksheet" do
      assert_equal "DNA Collections Form", spreadsheet.sheet(0).cell(1,1)
    end

    should "should have a data worksheet and ranges worksheet" do
      assert_instance_of SampleManifestExcel::Worksheet::DataWorksheet, download.data_worksheet
      assert_instance_of SampleManifestExcel::Worksheet::RangesWorksheet, download.ranges_worksheet
    end

    should "should have styles" do
      assert_equal 5, download.styles.count
    end

    should "column list should be extracted from full column list based on required columns names" do
      assert_equal 0, download.column_list.count
      assert_instance_of SampleManifestExcel::ColumnList, download.column_list
    end

    should "ranges should have absolute references" do
      range = download.range_list.ranges.values.first
      assert_equal "Ranges!#{range.reference}", range.absolute_reference
      assert download.range_list.all? {|k, range| range.absolute_reference.present?}
    end

  end

  context "Plate default download" do

    setup do
      @download = SampleManifestExcel::Download::PlateDefault.new(sample_manifest, column_list, range_list, styles)
    end

    should "have correct number of columns" do
      assert_equal 35, SampleManifestExcel::Download::PlateDefault.column_names.count
      assert_equal 35, download.column_list.count
    end

    should "have proper type" do
      assert_equal 'Plates', download.type
    end

  end

  context "Plate full download" do

    setup do
      @download = SampleManifestExcel::Download::PlateFull.new(sample_manifest, column_list, range_list, styles)
    end

    should "have correct number of columns" do
      assert_equal 51, SampleManifestExcel::Download::PlateFull.column_names.count
      assert_equal 51, download.column_list.count
    end

    should "have proper type" do
      assert_equal 'Plates', download.type
    end

  end

  context "Plate rnachip download" do

    setup do
      @download = SampleManifestExcel::Download::PlateRnachip.new(sample_manifest, column_list, range_list, styles)
    end

    should "have correct number of columns" do
      assert_equal 24, SampleManifestExcel::Download::PlateRnachip.column_names.count
      assert_equal 24, download.column_list.count
    end

    should "have proper type" do
      assert_equal 'Plates', download.type
    end

  end

  context "Tube default download" do

    setup do
      @download = SampleManifestExcel::Download::TubeDefault.new(tube_sample_manifest, column_list, range_list, styles)
    end

    should "have correct number of columns" do
      assert_equal 34, SampleManifestExcel::Download::TubeDefault.column_names.count
      assert_equal 34, download.column_list.count
    end

    should "have proper type" do
      assert_equal 'Tubes', download.type
    end

  end

  context "Tube full download" do

    setup do
      @download = SampleManifestExcel::Download::TubeFull.new(tube_sample_manifest, column_list, range_list, styles)
    end

    should "have correct number of columns" do
      assert_equal 50, SampleManifestExcel::Download::TubeFull.column_names.count
      assert_equal 50, download.column_list.count
    end

    should "have proper type" do
      assert_equal 'Tubes', download.type
    end

  end

  context "Tube rnachip download" do

    setup do
      @download = SampleManifestExcel::Download::TubeRnachip.new(tube_sample_manifest, column_list, range_list, styles)
    end

    should "have correct number of columns" do
      assert_equal 23, SampleManifestExcel::Download::TubeRnachip.column_names.count
      assert_equal 23, download.column_list.count
    end

    should "have proper type" do
      assert_equal 'Tubes', download.type
    end

  end

  context "Multiplexed library default download" do

    setup do
      @download = SampleManifestExcel::Download::MultiplexedLibraryDefault.new(tube_sample_manifest, column_list, range_list, styles)
    end

    should "have correct number of columns" do
      all_column_names = [:sanger_tube_id, :tag_group, :tag_index, :tag2_group, :tag2_index, :library_type, :insert_size_from, :insert_size_to, :sanger_sample_id,:supplier_sample_name, :cohort, :volume, :conc, :gender, :country_of_origin, :geographical_region, :ethnicity, :dna_source, :date_of_sample_collection, :date_of_dna_extraction, :is_sample_a_control?, :is_re_submitted_sample?, :dna_extraction_method, :sample_purified?, :purification_method, :concentration_determined_by, :dna_storage_conditions, :mother, :father, :sibling, :gc_content, :public_name, :taxon_id, :common_name, :sample_description, :strain, :sample_visibility, :sample_type, :sample_accession_number, :donor_id, :phenotype]
      assert_equal 41, SampleManifestExcel::Download::MultiplexedLibraryDefault.column_names.count
      assert_equal 41, download.column_list.count
      assert_equal all_column_names, SampleManifestExcel::Download::MultiplexedLibraryDefault.column_names
    end

    should "have proper type" do
      assert_equal 'Tubes', download.type
    end

  end

  def sample_manifest
    @sample_manifest ||= create(:sample_manifest_with_samples)
  end

  def tube_sample_manifest
    @sample_manifest_tube ||= create(:tube_sample_manifest_with_samples)
  end

  def column_list
    @column_list ||= SampleManifestExcel::ColumnList.new(YAML::load_file(File.expand_path(File.join(Rails.root,"test","data", "sample_manifest_excel","sample_manifest_all_columns.yml"))))
  end

  def range_list
    @range_list ||= SampleManifestExcel::RangeList.new(YAML::load_file(File.expand_path(File.join(Rails.root,"test","data", "sample_manifest_excel","sample_manifest_validation_ranges.yml"))))
  end

  def styles
    @styles ||= YAML::load_file(File.expand_path(File.join(Rails.root,"test","data", "sample_manifest_excel","sample_manifest_styles.yml")))
  end

  def save_file
    download.save('test.xlsx')
    @spreadsheet = Roo::Spreadsheet.open('test.xlsx')
  end

  def teardown
    File.delete('test.xlsx') if File.exists?('test.xlsx')
  end

end
