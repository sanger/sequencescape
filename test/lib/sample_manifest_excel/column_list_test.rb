require 'test_helper'

class ColumnListTest < ActiveSupport::TestCase

  attr_reader :column_list, :column_headings, :yaml, :valid_columns

  def setup
    @yaml = YAML::load_file(File.expand_path(File.join(Rails.root,"test","data", "sample_manifest_excel","sample_manifest_columns.yml")))
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

  test "#with_attributes should return a list of columns which have attributes" do
    column_list = SampleManifestExcel::ColumnList.new
    column_1 = SampleManifestExcel::Column.new(name: :column_1, heading: "Column 1")
    column_2 = SampleManifestExcel::Column.new(name: :column_2, heading: "Column 1", attribute: {attribute_column: true})
    column_list.add column_1
    column_list.add column_2
    assert_equal 1, column_list.with_attributes.count
    assert_equal column_2, column_list.with_attributes.first
  end

  test "#with_validations should return a list of columns which have validations" do
    assert_equal 1, column_list.with_validations.count
  end

  test "#without_protections should return a list of columns which do not have protection" do
    assert_equal 7, column_list.without_protections.count
  end

  test "#add_ranges should add first cell, last cell positions and range to columns" do
    column_list.add_ranges(10, 15)
    column = column_list.columns.values.first
    assert_equal "#{column.position_alpha}10:#{column.position_alpha}15", column.range
    assert column_list.all? {|k, column| column.range.present?}
  end

  test "#unlock should assign the right unlock_num to columns" do
    column_list.unlock(3)
    columns = column_list.without_protections
    assert columns.all? {|column| column.unlock_num == 3}
    column = column_list.find_by("well")
    refute column.unlock_num
  end
end