require 'test_helper'

class ColumnListTest < ActiveSupport::TestCase
  include SampleManifestExcel::Helpers

  attr_reader :column_list, :yaml, :ranges, :conditional_formattings

  def setup
    folder = File.join('test', 'data', 'sample_manifest_excel', 'extract')
    @yaml = load_file(folder, 'columns')
    @conditional_formattings = SampleManifestExcel::ConditionalFormattingDefaultList.new(load_file(folder, 'conditional_formattings'))
    @column_list = SampleManifestExcel::ColumnList.new(yaml, conditional_formattings)
    @ranges = build(:range_list, options: load_file(folder, 'ranges'))
  end

  test 'should create a list of columns' do
    assert_equal yaml.length, column_list.count
  end

  test 'columns should have conditional formattings' do
    assert_equal yaml[:gender][:conditional_formattings].length, column_list.find_by(:gender).conditional_formattings.count
    assert_equal yaml[:sibling][:conditional_formattings].length, column_list.find_by(:sibling).conditional_formattings.count
  end

  test '#headings should return headings' do
    assert_equal yaml.values.collect { |column| column[:heading] }, column_list.headings
  end

  test '#find_by returns correct column' do
    assert column_list.find_by(yaml.keys.first)
  end

  test 'each column should have a number' do
    column_list.each_with_index do |(k, _v), i|
      assert_equal i + 1, column_list.find_by(k).number
    end
  end

  test '#extract should return correct list of columns' do
    names = column_list.keys[0..5]
    list = column_list.extract(names)
    assert_equal yaml.length, column_list.count
    assert_equal names.length, list.count
    names.each_with_index do |name, i|
      assert_equal i + 1, list.find_by(name).number
    end
  end

  test '#extract should not affect original list of columns' do
    column_number = column_list.values[4].number
    names = column_list.keys[0..2] + column_list.keys[4..5]
    list = column_list.extract(names)
    assert_equal column_number, column_list.values[4].number
  end

  test '#add adds column to column list' do
    list = SampleManifestExcel::ColumnList.new
    column = SampleManifestExcel::Column.new(name: :plate_id, heading: 'Plate ID')
    list.add(column)
    assert_equal 1, list.count
    assert_equal 1, list.find_by(:plate_id).number
  end

  test '#add_with_dup should add dupped column' do
    list = SampleManifestExcel::ColumnList.new
    column = SampleManifestExcel::Column.new(name: :plate_id, heading: 'Plate ID')
    list.add_with_dup(column)
    refute_equal column, list.find_by(:plate_id)
  end

  test '#update should update columns' do
    column_list.update(10, 15, ranges, Axlsx::Workbook.new.add_worksheet)
    assert column_list.all? { |_k, column| column.updated? }
  end

  test 'should be comparable' do
    assert_equal column_list, SampleManifestExcel::ColumnList.new(yaml, conditional_formattings)
    yaml.shift
    refute_equal column_list, SampleManifestExcel::ColumnList.new(yaml, conditional_formattings)
  end

  test 'should duplicate correctly' do
    dupped = column_list.dup
    column_list.update(10, 15, ranges, Axlsx::Workbook.new.add_worksheet)
    refute dupped.any? { |_k, column| column.updated? }
  end
end
