require_relative '../../test_helper'

class ConditionalFormattingListTest < ActiveSupport::TestCase

  attr_reader :conditional_formatting_list, :rules, :worksheet, :options

  def setup
    @rules = YAML::load_file(File.expand_path(File.join(Rails.root,"test","data", "sample_manifest_excel","conditional_formatting.yml")))
    @conditional_formatting_list = SampleManifestExcel::ConditionalFormattingList.new(rules)
    @worksheet = Axlsx::Workbook.new.add_worksheet
    @options = build(:range).references.merge(worksheet: worksheet)
  end

  test "it should have the correct number of options" do
    assert_equal rules.length, conditional_formatting_list.count
  end

  test "#options should give a list of conditional formatting options" do
    assert_equal rules.length, conditional_formatting_list.options.count
    assert rules.values.all? { |rule| conditional_formatting_list.options.include? rule["options"] }
  end

  test "#update should update all of the conditional formatting rules" do
    conditional_formatting_list.update(options)
    assert conditional_formatting_list.each_item.all? { |conditional_formatting| conditional_formatting.styled? }
  end

  test "#update should update the worksheet with conditional formatting rules" do
    conditional_formatting_list.update(options)
    assert_equal rules.length, worksheet.conditional_formatting_rules.to_a.first.rules.length
    assert conditional_formatting_list.saved?
  end

  #TODO: This is in the wrong place. Probably should be tested in conditional formatting. Getting formula from worksheet is ugly.
  test "#update with formula should correctly assign the formula to the worksheet" do
    conditional_formatting_list = SampleManifestExcel::ConditionalFormattingList.new(rule_1: FactoryGirl.attributes_for(:conditional_formatting_with_formula))
    conditional_formatting_list.update(options)
    assert conditional_formatting_list.saved?
    assert_equal ERB::Util.html_escape(SampleManifestExcel::Formula.new(options.merge(FactoryGirl.attributes_for(:conditional_formatting_with_formula)[:formula])).to_s), worksheet.conditional_formatting_rules.to_a.first.rules.first.formula.first
  end

end