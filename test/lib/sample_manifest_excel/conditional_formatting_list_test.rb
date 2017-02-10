require 'test_helper'

class ConditionalFormattingListTest < ActiveSupport::TestCase
  include SampleManifestExcel::Helpers

  attr_reader :conditional_formatting_list, :rules, :worksheet, :options

  def setup
    folder = File.join('test', 'data', 'sample_manifest_excel', 'extract')
    @rules = load_file(folder, 'conditional_formattings')
    @conditional_formatting_list = SampleManifestExcel::ConditionalFormattingList.new(rules)
    @worksheet = Axlsx::Workbook.new.add_worksheet
    @options = build(:range).references.merge(worksheet: worksheet)
  end

  test 'it should have the correct number of options' do
    assert_equal rules.length, conditional_formatting_list.count
  end

  test '#options should give a list of conditional formatting options' do
    assert_equal rules.length, conditional_formatting_list.options.count
    assert rules.values.all? { |rule| conditional_formatting_list.options.include? rule['options'] }
  end

  test '#update should update all of the conditional formatting rules' do
    conditional_formatting_list.update(options)
    assert conditional_formatting_list.each_item.all? { |conditional_formatting| conditional_formatting.styled? }
  end

  test '#update should update the worksheet with conditional formatting rules' do
    conditional_formatting_list.update(options)
    assert_equal rules.length, worksheet.conditional_formatting_rules.to_a.first.rules.length
    assert options[:reference], worksheet.conditional_formatting_rules.to_a.first.sqref
    assert conditional_formatting_list.saved?
  end

  test '#update should only work if there are some conditional formattings in the list' do
    conditional_formatting_list = SampleManifestExcel::ConditionalFormattingList.new
    conditional_formatting_list.update(options)
    refute conditional_formatting_list.saved?
  end

  # TODO: This is in the wrong place. Probably should be tested in conditional formatting. Getting formula from worksheet is ugly.
  test '#update with formula should correctly assign the formula to the worksheet' do
    conditional_formatting_list = SampleManifestExcel::ConditionalFormattingList.new(rule_1: FactoryGirl.attributes_for(:conditional_formatting_with_formula))
    conditional_formatting_list.update(options)
    assert conditional_formatting_list.saved?
    assert_equal ERB::Util.html_escape(SampleManifestExcel::Formula.new(options.merge(FactoryGirl.attributes_for(:conditional_formatting_with_formula)[:formula])).to_s), worksheet.conditional_formatting_rules.to_a.first.rules.first.formula.first
  end

  test 'should be comparable' do
    assert_equal conditional_formatting_list, SampleManifestExcel::ConditionalFormattingList.new(rules)
    rules.shift
    refute_equal conditional_formatting_list, SampleManifestExcel::ConditionalFormattingList.new(rules)
    refute_equal Array.new, SampleManifestExcel::ConditionalFormattingList.new(rules)
  end

  test 'should be duplicated correctly' do
    dup = conditional_formatting_list.dup
    conditional_formatting_list.update(options)
    refute dup.each_item.any? { |conditional_formatting| conditional_formatting.styled? }
  end
end
