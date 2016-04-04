require 'test_helper'

class ColumnListTest < ActiveSupport::TestCase

  attr_reader :column_list, :column_headings, :yaml, :valid_columns

  def setup
    @yaml = YAML::load_file(File.expand_path(File.join(Rails.root,"test","data", "sample_manifest_columns.yml")))
    @column_list = SampleManifestExcel::ColumnList.new(yaml)
    @valid_columns = yaml.collect { |k,v| k if v.present? }.compact
  end

  test "should create a list of columns" do
    assert_equal yaml.length-1, column_list.count
  end

  test "#headings should return headings" do
    assert_equal yaml.values.compact.collect { |column| column["heading"] }, column_list.headings
  end

  test "#find_by returns correct column" do
    assert column_list.find_by(yaml.keys.first)
  end

  test "each column should have a position" do
    valid_columns.each_with_index do |column, i|
      assert_equal i+1,column_list.find_by(column).position
    end
  end

  test "#extract should return correct list of columns" do
    names = yaml.each_with_index.map { |(k, v), i|  k if i.odd? }.compact
    column_list_new = column_list.extract(names)
    assert_equal names.length, column_list_new.count
    names.each_with_index do |name, i|
      assert column_list_new.find_by(name)
      assert_equal i+1, column_list_new.find_by(name).position 
    end
  end

  test "#add adds column to column list" do
    column_list_new = SampleManifestExcel::ColumnList.new
    column = SampleManifestExcel::Column.new(name: :plate_id, heading: "Plate ID")
    column_list_new.add(column)
    assert_equal 1, column_list_new.columns.count
    assert_equal 1, column_list_new.find_by(:plate_id).position
  end

  test "#add_with_dup should add dupped column" do
    column_list_new = SampleManifestExcel::ColumnList.new
    column = SampleManifestExcel::Column.new(name: :plate_id, heading: "Plate ID")
    column_list_new.add_with_dup(column)
    refute_equal column, column_list_new.find_by(:plate_id)
  end

end