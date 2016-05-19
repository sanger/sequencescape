require 'test_helper'

class ConditionalFormattingRuleTest < ActiveSupport::TestCase

  attr_reader :conditional_formatting_rule, :simple_conditional_formatting_rule, :range, :style, :column, :worksheet, :formula

  def setup
    @formula  = {type: :len, operator: ">", operand: 10}
    @conditional_formatting_rule = SampleManifestExcel::ConditionalFormattingRule.new(style: :style_name, formula: formula, options: {'option1' => 'value1', 'option2' => 'value2'})
    @simple_conditional_formatting_rule = build :conditional_formatting_rule
    @range = build :range
    @style = build :style
    @column = build :column_with_position
  end

  test "should have options, style, formula" do
  	assert conditional_formatting_rule.options
    assert conditional_formatting_rule.style
    assert conditional_formatting_rule.formula
  end

  test "#prepare should prepare conditional formatting" do
    conditional_formatting_rule.prepare(style, "A1", "A5:A111")
    assert_equal style.reference, conditional_formatting_rule.options['dxfId']

    assert_equal SampleManifestExcel::Formula.new(formula).update(first_cell: "A1", absolute_reference: "A5:A111").to_s, conditional_formatting_rule.options['formula']
  end

  test "#set_style should set style" do
  	conditional_formatting_rule.set_style(style)
  	assert_equal style.reference, conditional_formatting_rule.options['dxfId']
    refute conditional_formatting_rule.set_style(style)
    refute simple_conditional_formatting_rule.set_style(style)
  end

end