require 'test_helper'

class ColumnListTest < ActiveSupport::TestCase

  attr_reader :column_list, :column_headings, :yaml, :valid_columns, :ranges, :styles, :worksheet

  def setup
    @yaml = YAML::load_file(File.expand_path(File.join(Rails.root,"test","data", "sample_manifest_excel","sample_manifest_columns.yml")))
    @column_list = SampleManifestExcel::ColumnList.new(yaml)
    @valid_columns = yaml.collect { |k,v| k if v.present? }.compact
    @ranges = build :range_list_with_absolute_reference
    style = build :style
    @styles = {unlock: style, style_name: style, wrong_value: style, empty_cell: style}
  end

  test "should create a list of columns" do
    assert_equal yaml.length-1, column_list.count
  end

  test "should add the attributes to the column list" do
    assert column_list.find_by(:sanger_plate_id).attribute?
    assert column_list.find_by(:well).attribute?
    assert column_list.find_by(:sanger_sample_id).attribute?
    assert column_list.find_by(:donor_id).attribute?
    assert column_list.find_by(:sanger_tube_id).attribute?
  end

  test "#headings should return headings" do
    assert_equal yaml.values.compact.collect { |column| column[:heading] }, column_list.headings
  end

  test "#find_by returns correct column" do
    assert column_list.find_by(yaml.keys.first)
  end

  test "each column should have a number" do
    valid_columns.each_with_index do |column, i|
      assert_equal i+1,column_list.find_by(column).number
    end
  end

  test "#extract should return correct list of columns" do
    names = yaml.each_with_index.map { |(k, v), i|  k if i.odd? }.compact
    column_list_new = column_list.extract(names)
    assert_equal names.length, column_list_new.count
    names.each_with_index do |name, i|
      assert column_list_new.find_by(name)
      assert_equal i+1, column_list_new.find_by(name).number
    end
  end

  test "#add adds column to column list" do
    column_list_new = SampleManifestExcel::ColumnList.new
    column = SampleManifestExcel::Column.new(name: :plate_id, heading: "Plate ID")
    column_list_new.add(column)
    assert_equal 1, column_list_new.columns.count
    assert_equal 1, column_list_new.find_by(:plate_id).number
  end

  test "#add_with_dup should add dupped column" do
    column_list_new = SampleManifestExcel::ColumnList.new
    column = SampleManifestExcel::Column.new(name: :plate_id, heading: "Plate ID")
    column_list_new.add_with_dup(column)
    refute_equal column, column_list_new.find_by(:plate_id)
  end

  test "#with_attributes should return a list of columns which have attributes" do
    assert_equal 5, column_list.with_attributes.count
    column_list = SampleManifestExcel::ColumnList.new
    column_1 = SampleManifestExcel::Column.new(name: :column_1, heading: "Column 1")
    column_2 = SampleManifestExcel::Column.new(name: :column_2, heading: "Column 1", attribute: {attribute_column: true})
    column_list.add column_1
    column_list.add column_2
    assert_equal 1, column_list.with_attributes.count
    assert_equal column_2, column_list.with_attributes.first
  end

  test "#with_validations should return a list of columns which have validations" do
    assert_equal 2, column_list.with_validations.count
  end

  test "#with_unlocked should return a list of columns which are unlocked" do
    assert_equal 8, column_list.with_unlocked.count
  end

  test "#with_conditional_formatting_rules should return a list of columns which have conditional formatting rules" do
    assert_equal 2, column_list.with_conditional_formatting_rules.count
  end

  test "#prepare_columns should prepare columns" do
    column_list.prepare_columns(10, 15, styles, ranges)
    column_list.each { |k, column| assert column.position }
    assert column_list.with_unlocked.all? {|column| column.unlocked.is_a? Integer}
    column = column_list.find_by(:gender)
    assert_equal ranges.find_by(:gender).absolute_reference, column.validation.options[:formula1]
    rule = column.conditional_formatting_rules.last
    assert_equal styles[:wrong_value].reference, rule.options['dxfId']
    assert_match column.first_cell_relative_reference, rule.options['formula']
    assert_match ranges.find_by(:gender).absolute_reference, rule.options['formula']
  end

  test "#add_validation_and_conditional_formatting should add it to axlsx_worksheet" do
    axlsx_worksheet = build :axlsx_worksheet
    column_list.prepare_columns(10, 15, styles, ranges)
    column_list.add_validation_and_conditional_formatting(axlsx_worksheet)

    assert_equal column_list.with_validations.count, axlsx_worksheet.send(:data_validations).count
    column = column_list.with_validations.first
    assert_equal column.reference, axlsx_worksheet.send(:data_validations).first.sqref
    column = column_list.with_validations.last
    assert_equal column.reference, axlsx_worksheet.send(:data_validations).last.sqref
    assert axlsx_worksheet.send(:data_validations).find {|validation| validation.formula1 == column_list.find_by(:gender).validation.options[:formula1]}

    assert_equal 2, axlsx_worksheet.send(:conditional_formattings).count
    column = column_list.find_by(:sibling)
    assert axlsx_worksheet.send(:conditional_formattings).any? {|conditional_formatting| conditional_formatting.sqref == column.reference}
    conditional_formatting = axlsx_worksheet.send(:conditional_formattings).select {|conditional_formatting| conditional_formatting.sqref == column.reference}
    assert_equal column.conditional_formatting_options.count, conditional_formatting.last.rules.count
    assert_equal column.conditional_formatting_options.last['formula'], conditional_formatting.last.rules.last.formula.first
  end

end