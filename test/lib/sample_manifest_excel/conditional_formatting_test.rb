require_relative '../../test_helper'

class ConditionalFormattingTest < ActiveSupport::TestCase

  attr_reader :rule, :worksheet, :conditional_formatting

  def setup
    @worksheet = Axlsx::Workbook.new.add_worksheet
  end

  context "without formula" do

    setup do
      @rule = { type: :empty_cell, style: { bg_color: '82CAFA', type: :dxf}, options: { option1: "some_value", option2: "another_value"}}.with_indifferent_access
      @conditional_formatting = SampleManifestExcel::ConditionalFormatting.new(rule)
    end

    should "have a type" do
      assert_equal (rule[:type]), conditional_formatting.type
    end

    should "have some options" do
      assert_equal (rule[:options]), conditional_formatting.options
    end

    should "have a style" do
      assert_equal (rule[:style]), conditional_formatting.style
    end

    should "not have a formula" do
      refute conditional_formatting.formula
    end

    should "update the style from a workbook" do
      assert conditional_formatting.update(worksheet: worksheet).styled?
    end

    should "#to_h should produce a hash of options" do
      assert_equal conditional_formatting.options, conditional_formatting.to_h
    end

  end

  context "with formula" do

    attr_reader :options, :formula, :references

    setup do
      @references = build(:range).references
      @formula = { type: :len, operator: :lt, operand: 333}
      @rule = {formula: formula, style: { bg_color: '82CAFA', type: :dxf}, options: { option1: "some_value", option2: "another_value"}}.with_indifferent_access
      @conditional_formatting = SampleManifestExcel::ConditionalFormatting.new(rule)
    end

    should "have a formula" do
      assert_equal SampleManifestExcel::Formula.new(formula), conditional_formatting.formula
    end

    should "update the formula if cell references are added" do
      assert_equal SampleManifestExcel::Formula.new(formula.merge(references)).to_s, conditional_formatting.update(references).options['formula']
    end

    should "#to_h should produce a hash of options" do
      assert_equal conditional_formatting.options, conditional_formatting.to_h
    end

    should "update the style from a worksheet" do
      assert conditional_formatting.update(references.merge(worksheet: worksheet)).styled?
    end

  end

end