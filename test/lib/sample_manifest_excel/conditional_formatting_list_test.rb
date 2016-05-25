require_relative '../../test_helper'

class ConditionalFormattingListTest < ActiveSupport::TestCase

  attr_reader :conditional_formatting_list, :options

  def setup
    @options = YAML::load_file(File.expand_path(File.join(Rails.root,"test","data", "sample_manifest_excel","conditional_formatting.yml")))
    @conditional_formatting_list = SampleManifestExcel::ConditionalFormattingList.new(options)
  end

  test "it should have the correct number of options" do
    assert_equal options.length, conditional_formatting_list.count
  end

  test "#options should give a list of conditional formatting options" do
    assert_equal options.length, conditional_formatting_list.options.count
    p conditional_formatting_list.options
    assert options.all? { |option| conditional_formatting_list.options.include? option }
  end

  test "#update should update all of the conditional formatting rules" do
    conditional_formatting_list.update(workbook: Axlsx::Workbook.new)
    assert conditional_formatting_list.all? { |k, conditional_formatting| conditional_formatting.styled? }
  end

  
end
