# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SequencescapeExcel::ConditionalFormattingDefault, :sample_manifest, :sample_manifest_excel,
               type: :model do
  context 'basic' do
    let(:options) do
      {
        style: {
          bg_color: '82CAFA',
          type: :dxf
        },
        options: {
          type: :cellIs,
          formula: 'FALSE',
          operator: :equal,
          priority: 1
        },
        type: 'a_type'
      }.with_indifferent_access
    end

    let(:conditional_formatting_default) { described_class.new(options) }

    it 'has a type' do
      expect(conditional_formatting_default.type).to eq(options[:type].to_sym)
    end

    it 'has some options' do
      expect(conditional_formatting_default.options).to eq(options[:options])
    end

    it 'has some style' do
      expect(conditional_formatting_default.style).to eq(options[:style])
    end

    it 'must not be an expression' do
      expect(conditional_formatting_default).not_to be_expression
    end

    it '#combine with conditional_formatting will produce correct options' do
      expect(conditional_formatting_default.combine).to eq(options.except(:type))
    end

    it 'be comparable' do
      expect(conditional_formatting_default).to eq(described_class.new(options))
    end
  end

  context 'expression' do
    let(:options) do
      {
        style: {
          bg_color: 'FF0000',
          type: :dxf
        },
        options: {
          type: :expression,
          priority: 2
        },
        type: :another_type
      }.with_indifferent_access
    end
    let(:conditional_formatting_default) { described_class.new(options) }

    it 'must be an expression' do
      expect(conditional_formatting_default).to be_expression
    end

    it '#combine with conditional_formatting will produce correct options' do
      combination = conditional_formatting_default.combine
      expect(combination[:formula]).to be_present
      expect(combination[:formula][:type]).to eq(:another_type)
    end
  end

  context 'with formula' do
    let(:options) do
      {
        style: {
          bg_color: 'FF0000',
          type: :dxf
        },
        options: {
          type: :expression,
          priority: 2
        },
        type: :len
      }.with_indifferent_access
    end
    let(:conditional_formatting_default) { described_class.new(options) }

    it 'must be an expression' do
      expect(conditional_formatting_default).to be_expression
    end

    it '#combine with conditional_formatting will produce correct options' do
      to_combine = { formula: { operator: '>', operand: 20 } }.with_indifferent_access
      combination = conditional_formatting_default.combine(to_combine)
      expect(combination[:formula]).to be_present
      expect(combination[:formula]).to eq(to_combine[:formula].merge(type: :len))
    end
  end
end
