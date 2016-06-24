require_relative '../../test_helper'

class ConfigurationTest < ActiveSupport::TestCase

  attr_reader :configuration

  def setup
    @configuration = SampleManifestExcel::Configuration.new
  end

  test "should be comparable" do
    assert_equal SampleManifestExcel::Configuration.new, configuration
  end

  test "should be able to add a new file" do
    configuration.add_file "a_new_file"
    assert_equal SampleManifestExcel::Configuration::FILES.length+1, configuration.files.length
    assert configuration.files.include?(:a_new_file)
    assert configuration.respond_to?("a_new_file=")
  end

  context "without a folder" do

    setup do
      configuration.load!
    end

    should "not be loaded" do
      refute configuration.loaded?
    end
  end

  context "with a valid folder" do

    attr_reader :folder

    setup do
      @folder = File.join("test", "data", "sample_manifest_excel")
      configuration.folder = folder
      configuration.load!
    end

    should "be loaded" do
      assert configuration.loaded?
    end

    should "load the columns" do
      columns = SampleManifestExcel::ColumnList.new(configuration.load_file(folder, "columns"), configuration.load_file(folder, "conditional_formattings"))
      assert_equal columns, configuration.columns.all
      configuration.manifest_types.each do |k,v|
        assert_equal columns.extract(v), configuration.columns.send(k)
      end
    end

    should "load the conditional formattings" do
      assert_equal configuration.load_file(folder, "conditional_formattings"), configuration.conditional_formattings
    end

    should "load the manifest types" do
      assert_equal configuration.load_file(folder, "manifest_types"), configuration.manifest_types
    end

    should "load the ranges" do
      assert_equal configuration.load_file(folder, "ranges"), configuration.ranges
    end

  end
  
end