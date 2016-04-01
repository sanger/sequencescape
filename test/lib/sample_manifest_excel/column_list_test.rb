require 'test_helper'

class ColumnListTest < ActiveSupport::TestCase

  attr_reader :column_list, :column_headings, :yaml

  def setup
    @yaml = YAML::load_file(File.expand_path(File.join(Rails.root,"test","data", "sample_manifest_columns.yml")))
    @column_list = SampleManifestExcel::ColumnList.new(yaml)
  end

  test "should create a list of columns" do
    assert_equal yaml.length-1, column_list.count
  end

  test "#headings should return headings" do
    assert_equal yaml.values.compact.collect { |column| column["heading"] }, column_list.headings
  end

end