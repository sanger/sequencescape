require 'test_helper'

class ConditionalFormattingRuleTest < ActiveSupport::TestCase

  attr_reader :conditional_formatting_rule, :range, :style, :column, :worksheet

  def setup
    @conditional_formatting_rule = SampleManifestExcel::ConditionalFormattingRule.new({'option1' => 'value1', 'option2' => 'value2', 'dxfId' => :style_name, 'formula' => 'ISERROR(MATCH(first_cell_relative_reference,range_absolute_reference,0)>0)'})
    @range = build :range_with_absolute_reference
    @style = build :style
    @column = build :column
  end

  test "should have options" do
  	assert conditional_formatting_rule.options
  end

  test "#set_style should set style" do
  	conditional_formatting_rule.set_style(style)
  	assert_equal style.reference, conditional_formatting_rule.options['dxfId']
  end

  test "#set_first_cell_in_formula should set the column first cell relative reference in formula" do
  	column.set_number(3).add_reference(10, 15)
  	conditional_formatting_rule.set_first_cell_in_formula(column.first_cell_relative_reference)
  	assert_match column.first_cell_relative_reference, conditional_formatting_rule.options['formula']
  end

  test "#set_range_reference_in_formula should set range absolute reference in formula" do
  	conditional_formatting_rule.set_range_reference_in_formula(range)
  	assert_match range.absolute_reference, conditional_formatting_rule.options['formula']
  end

end