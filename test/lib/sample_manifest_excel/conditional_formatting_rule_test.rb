require 'test_helper'

class ConditionalFormattingRuleTest < ActiveSupport::TestCase

  attr_reader :conditional_formatting_rule, :simple_conditional_formatting_rule, :range, :style, :column, :worksheet

  def setup
    @conditional_formatting_rule = SampleManifestExcel::ConditionalFormattingRule.new(style: :style_name, formula: 'ISERROR(MATCH(first_cell_relative_reference,range_absolute_reference,0)>0)', options: {'option1' => 'value1', 'option2' => 'value2'})
    @simple_conditional_formatting_rule = build :simple_conditional_formatting_rule
    @range = build :range_with_absolute_reference
    @style = build :style
    @column = build :column_with_position
  end

  test "should have options, style, formula" do
  	assert conditional_formatting_rule.options
    assert conditional_formatting_rule.style
    assert conditional_formatting_rule.formula
  end

  test "#prepare should prepare conditional formatting" do
    conditional_formatting_rule.prepare(style, column.first_cell_relative_reference, range)
    assert_equal style.reference, conditional_formatting_rule.options['dxfId']
    assert_match column.first_cell_relative_reference, conditional_formatting_rule.options['formula']
    assert_match range.absolute_reference, conditional_formatting_rule.options['formula']
  end

  test "#set_style should set style" do
  	conditional_formatting_rule.set_style(style)
  	assert_equal style.reference, conditional_formatting_rule.options['dxfId']
    refute conditional_formatting_rule.set_style(style)
    refute simple_conditional_formatting_rule.set_style(style)
  end

  test "#set_first_cell_in_formula should set the column first cell relative reference in formula" do
  	conditional_formatting_rule.set_first_cell_in_formula(column.first_cell_relative_reference)
  	assert_match column.first_cell_relative_reference, conditional_formatting_rule.formula
    refute simple_conditional_formatting_rule.set_first_cell_in_formula(column.first_cell_relative_reference)
  end

  test "#set_range_reference_in_formula should set range absolute reference in formula" do
  	conditional_formatting_rule.set_range_reference_in_formula(range)
  	assert_match range.absolute_reference, conditional_formatting_rule.formula
  end

end