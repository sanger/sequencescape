require 'rails_helper'

RSpec.describe SampleManifestExcel::ConditionalFormatting, type: :model, sample_manifest_excel: true do
  let(:worksheet) { Axlsx::Workbook.new.add_worksheet }
  let(:rule) { { name: :rule1, style: { bg_color: '82CAFA', type: :dxf }, options: { option1: 'some_value', option2: 'another_value' } }.with_indifferent_access }

  it 'is comparable' do
    expect(SampleManifestExcel::ConditionalFormatting.new(rule)).to eq(SampleManifestExcel::ConditionalFormatting.new(rule))
    expect(SampleManifestExcel::ConditionalFormatting.new(rule)).to_not eq(SampleManifestExcel::ConditionalFormatting.new(rule.merge(options: { option1: 'another_value' })))
  end

  it 'is not valid without a name' do
    expect(SampleManifestExcel::ConditionalFormatting.new(rule)).to be_valid
    expect(SampleManifestExcel::ConditionalFormatting.new(rule.except(:name))).to_not be_valid
  end

  it 'is not valid without a name' do
    expect(SampleManifestExcel::ConditionalFormatting.new(rule.except(:options))).to_not be_valid
  end

  context 'without formula' do
    let(:conditional_formatting) { SampleManifestExcel::ConditionalFormatting.new(rule) }

    it 'has some options' do
      expect(conditional_formatting.options).to eq((rule[:options]))
    end

    it 'has a style' do
      expect(conditional_formatting.style).to eq((rule[:style]))
    end

    it 'will not have a formula' do
      expect(conditional_formatting.formula).to be_nil
    end

    it 'update the style from a workbook' do
      expect(conditional_formatting.update(worksheet: worksheet)).to be_styled
    end

    it '#to_h produces a hash of options' do
      expect(conditional_formatting.to_h).to eq(conditional_formatting.options)
    end

    it 'duplicates correctly' do
      dup = conditional_formatting.dup
      expect(dup.formula).to be_nil
      conditional_formatting.update(worksheet: worksheet)
      expect(dup).to_not be_styled
    end
  end

  context 'with formula' do
    let(:references) { build(:range).references }
    let(:formula) { { type: :len, operator: '<', operand: 333 } }
    let(:conditional_formatting) { SampleManifestExcel::ConditionalFormatting.new(rule.merge(formula: formula)) }

    it 'has a formula' do
      expect(conditional_formatting.formula).to eq(SampleManifestExcel::Formula.new(formula))
    end

    it 'updates the formula if cell references are added' do
      expect(conditional_formatting.update(references).options['formula']).to eq(SampleManifestExcel::Formula.new(formula.merge(references)).to_s)
    end

    it '#to_h should produce a hash of options' do
      expect(conditional_formatting.to_h).to eq(conditional_formatting.options)
    end

    it 'update the style from a worksheet' do
      expect(conditional_formatting.update(references.merge(worksheet: worksheet))).to be_styled
    end

    it 'duplicate correctly' do
      dup = conditional_formatting.dup
      conditional_formatting.update(references.merge(worksheet: worksheet))
      expect(dup.options).to_not eq(conditional_formatting.options)
      expect(dup.formula).to_not eq(conditional_formatting.formula)
    end
  end
end
