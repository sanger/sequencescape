require 'test_helper'

class ConditionalFormattingDefaultTest < ActiveSupport::TestCase
  attr_reader :conditional_formatting_default, :options

  context 'basic' do
    setup do
      @options = { style: { bg_color: '82CAFA', type: :dxf },
                   options: { type: :cellIs, formula: 'FALSE', operator: :equal, priority: 1 },
                   type: 'a_type' }.with_indifferent_access
      @conditional_formatting_default = SampleManifestExcel::ConditionalFormattingDefault.new(options)
    end

    should 'have a type' do
      assert_equal options[:type].to_sym, conditional_formatting_default.type
    end

    should 'have some options' do
      assert_equal options[:options], conditional_formatting_default.options
    end

    should 'have some style' do
      assert_equal options[:style], conditional_formatting_default.style
    end

    should 'not be an expression' do
      refute conditional_formatting_default.expression?
    end

    should '#combine with conditional_formatting to produce correct options' do
      assert_equal options.except(:type), conditional_formatting_default.combine
    end

    should 'be comparable' do
      assert_equal SampleManifestExcel::ConditionalFormattingDefault.new(options), conditional_formatting_default
    end
  end

  context 'expression' do
    setup do
        @options = { style: { bg_color: 'FF0000', type: :dxf },
                     options: { type: :expression, priority: 2 },
                     type: :another_type }.with_indifferent_access
      @conditional_formatting_default = SampleManifestExcel::ConditionalFormattingDefault.new(options)
    end

    should 'be an expression' do
      assert conditional_formatting_default.expression?
    end

    should '#combine with conditional_formatting to produce correct options' do
      combination = conditional_formatting_default.combine
      assert combination[:formula].present?
      assert_equal :another_type, combination[:formula][:type]
    end
  end

  context 'with formula' do
    setup do
        @options = { style: { bg_color: 'FF0000', type: :dxf },
                     options: { type: :expression, priority: 2 },
                     type: :len }.with_indifferent_access
      @conditional_formatting_default = SampleManifestExcel::ConditionalFormattingDefault.new(options)
    end

    should 'be an expression' do
      assert conditional_formatting_default.expression?
    end

    should '#combine with conditional_formatting to produce correct options' do
      to_combine = { formula: { operator: '>', operand: 20 } }.with_indifferent_access
      combination = conditional_formatting_default.combine(to_combine)
      assert combination[:formula].present?
      assert_equal to_combine[:formula].merge(type: :len), combination[:formula]
    end
  end
end
