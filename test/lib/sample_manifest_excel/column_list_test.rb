require 'test_helper'

class ColumnListTest < ActiveSupport::TestCase

  include SampleManifestExcel::Helpers

  attr_reader :column_list,:yaml, :ranges, :conditional_formattings

  def setup
    folder = File.join("test","data", "sample_manifest_excel", "extract")
    @yaml = load_file(folder, "columns")
    @conditional_formattings = SampleManifestExcel::ConditionalFormattingDefaultList.new(load_file(folder, "conditional_formattings"))
    @column_list = SampleManifestExcel::ColumnList.new(yaml, conditional_formattings)
    @ranges = build(:range_list, options: load_file(folder, "ranges"))
  end

  test "should create a list of columns" do
    assert_equal yaml.length, column_list.count
  end

  test "should create a list of columns when passed a bunch of columns" do
    columns = build_list(:column, 5)
    column_list = SampleManifestExcel::ColumnList.new(build_list(:column, 5))
    assert_equal columns.length, column_list.count
    assert column_list.all? { |column| column_list.find_by(:name, column.name).present? }
  end

  test "columns should have conditional formattings" do
    assert_equal yaml[:gender][:conditional_formattings].length, column_list.find_by(:name, :gender).conditional_formattings.count
    assert_equal yaml[:sibling][:conditional_formattings].length, column_list.find_by(:name, :sibling).conditional_formattings.count
  end

  test "#headings should return headings" do
    assert_equal yaml.values.collect { |column| column[:heading] }, column_list.headings
  end

  test "#column_values should return all of the values for the column list" do
    sanger_sample_id_column = build(:sanger_sample_id_column)
    column_list.add(sanger_sample_id_column)
    assert_equal column_list.count, column_list.column_values.length
    assert_equal sanger_sample_id_column.value, column_list.column_values.last
  end

  test "#column_values with inserts should return all of the values for the column list along with the inserts" do
    names = column_list.names
    replacements = { names.first => "first", names.last => "last" }
    values = column_list.column_values(replacements)
    assert_equal "first", values.first
    assert_equal "last", values.last
  end

  test "each column should have a number" do
    column_list.each_with_index do |column, i|
      assert_equal column, column_list.find_by(:number, i+1)
    end
  end

  test "#extract should return correct list of columns" do
    names = column_list.names[0..5]
    list = column_list.extract(names)
    assert_equal yaml.length, column_list.count
    assert_equal names.length, list.count
    names.each_with_index do |name, i|
      assert_equal i+1, list.find_by(:name, name).number
    end
  end

  test "#extract should not affect original list of columns" do
    column_number = column_list.values[4].number
    names = column_list.names[0..2] + column_list.names[4..5]
    list = column_list.extract(names)
    assert_equal column_number, column_list.values[4].number
  end

  test "#extract should be able to extract columns by any key" do
    new_list = column_list.extract(column_list.headings)
    assert_equal column_list.count, new_list.count
  end

  test "#extract with invalid key should provide a descriptive error message" do
    bad_column = build(:column)
    new_list = column_list.extract(column_list.headings << bad_column.heading)
    refute new_list.valid?
    assert_match bad_column.heading, new_list.errors.full_messages.to_s
  end

  test "#update should update columns" do
    column_list.update(10, 15, ranges, Axlsx::Workbook.new.add_worksheet)
    assert column_list.all? { |column| column.updated? }
  end

  test "should duplicate correctly" do
    n = column_list.count
    dupped = column_list.dup
    assert_equal n, column_list.count
    assert_equal n, dupped.count
    column_list.update(10, 15, ranges, Axlsx::Workbook.new.add_worksheet)
    refute dupped.any? { |column| column.updated? }
  end

  test "should only be valid with some columns" do
    assert SampleManifestExcel::ColumnList.new(yaml, conditional_formattings).valid?
    refute SampleManifestExcel::ColumnList.new(nil, conditional_formattings).valid?
  end

  test "#find_by_or_null should return a null object if none exists for key and value" do
    assert_equal -1, column_list.find_by_or_null(:name, :bad_value).number
  end

end