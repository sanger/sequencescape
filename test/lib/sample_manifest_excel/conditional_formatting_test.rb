require_relative '../../test_helper'

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
      @options = { type: :len, operator: '>', operand: 30, first_cell: "A1", absolute_reference: "A1:A100", workbook: Axlsx::Workbook.new}
      @rule = { style: { bg_color: '82CAFA', type: :dxf}, formula: { type: :len, operator: '>', operand: 30 }, options: { option1: "some_value", option2: "another_value"}}
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

    should "update the style from a workbook" do
      assert conditional_formatting.update(options).options['dxfId']
    end

  end

end