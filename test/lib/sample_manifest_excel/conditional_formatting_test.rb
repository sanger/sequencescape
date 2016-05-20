require 'test_helper'

class ConditionalFormattingTest < ActiveSupport::TestCase

  attr_reader :rule, :workbook, :conditional_formatting

  context "without formula" do

    setup do
      @rule = { style: { bg_color: '82CAFA', type: :dxf}, options: { option1: "some_value", option2: "another_value"}}
      @workbook = Axlsx::Workbook.new
      @conditional_formatting = SampleManifestExcel::ConditionalFormatting.new(rule)
    end

    should "have some options" do
      assert_equal ({ option1: "some_value", option2: "another_value"}), conditional_formatting.options
    end

    should "have a style" do
      assert_equal ({ bg_color: '82CAFA', type: :dxf}), conditional_formatting.style

    end

    should "not have a formula" do
      refute conditional_formatting.formula
    end

    should "update the style from a workbook" do
      assert conditional_formatting.update(workbook: workbook).options['dxfId']
    end

    should "#to_h should produce a hash of options" do
      assert_equal conditional_formatting.options, conditional_formatting.to_h
    end


  end

  context "with formula" do

    attr_reader :options

    setup do
      @options = { type: :len, operator: '>', operand: 30, first_cell: "A1", absolute_reference: "A1:A100"}
      @rule = { style: { bg_color: '82CAFA', type: :dxf}, formula: { type: :len, operator: '>', operand: 30 }, options: { option1: "some_value", option2: "another_value"}}
      @workbook = Axlsx::Workbook.new
      @conditional_formatting = SampleManifestExcel::ConditionalFormatting.new(rule)
    end

    should "have a formula" do
      assert_equal SampleManifestExcel::Formula.new(options.except(:first_cell, :absolute_reference)), conditional_formatting.formula
    end

    should "update the formula if cell references are added" do
      assert_equal SampleManifestExcel::Formula.new(options).to_s, conditional_formatting.update(options).options['formula']
    end

    should "#to_h should produce a hash of options" do
      assert_equal conditional_formatting.options, conditional_formatting.to_h
    end

  end

  # attr_reader :conditional_formatting_rule, :simple_conditional_formatting_rule, :range, :style, :column, :worksheet, :formula

  # def setup
  #   @formula  = {type: :len, operator: ">", operand: 10}
  #   @conditional_formatting_rule = SampleManifestExcel::ConditionalFormattingRule.new(style: :style_name, formula: formula, options: {'option1' => 'value1', 'option2' => 'value2'})
  #   @simple_conditional_formatting_rule = build :conditional_formatting_rule
  #   @range = build :range
  #   @style = build :style
  #   @column = build :column_with_range
  # end

  # test "should have options, style, formula" do
  # 	assert conditional_formatting_rule.options
  #   assert conditional_formatting_rule.style
  #   assert conditional_formatting_rule.formula
  # end

  # test "#prepare should prepare conditional formatting" do
  #   conditional_formatting_rule.prepare(style, "A1", "A5:A111")
  #   assert_equal style.reference, conditional_formatting_rule.options['dxfId']

  #   assert_equal SampleManifestExcel::Formula.new(formula).update(first_cell: "A1", absolute_reference: "A5:A111").to_s, conditional_formatting_rule.options['formula']
  # end

  # test "#set_style should set style" do
  # 	conditional_formatting_rule.set_style(style)
  # 	assert_equal style.reference, conditional_formatting_rule.options['dxfId']
  #   refute conditional_formatting_rule.set_style(style)
  #   refute simple_conditional_formatting_rule.set_style(style)
  # end

end