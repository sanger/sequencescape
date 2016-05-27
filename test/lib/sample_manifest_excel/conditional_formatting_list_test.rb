require_relative '../../test_helper'

class ConditionalFormattingListTest < ActiveSupport::TestCase

  attr_reader :conditional_formatting_list, :rules

  def setup
    @rules = YAML::load_file(File.expand_path(File.join(Rails.root,"test","data", "sample_manifest_excel","conditional_formatting.yml")))
    @conditional_formatting_list = SampleManifestExcel::ConditionalFormattingList.new(rules)
  end

  test "it should have the correct number of options" do
    assert_equal rules.length, conditional_formatting_list.count
  end

  test "#options should give a list of conditional formatting options" do
    assert_equal rules.length, conditional_formatting_list.options.count
    assert rules.values.all? { |rule| conditional_formatting_list.options.include? rule["options"] }
  end

  test "#update should update all of the conditional formatting rules" do
    conditional_formatting_list.update(workbook: Axlsx::Workbook.new)
    assert conditional_formatting_list.each_item.all? { |conditional_formatting| conditional_formatting.styled? }
  end

  
end
