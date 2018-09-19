# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SequencescapeExcel::Validation, type: :model, sample_manifest_excel: true do
  let(:options) { { option1: 'value1', option2: 'value2', type: :whole, formula1: 'smth' } }
  let(:range) { build(:range) }

  it 'is not valid without options' do
    expect(SequencescapeExcel::Validation.new).to_not be_valid
  end

  it 'is comparable' do
    expect(SequencescapeExcel::Validation.new(options: options)).to eq(SequencescapeExcel::Validation.new(options: options))
    expect(SequencescapeExcel::Validation.new(options: options.except(:formula1))).to_not eq(SequencescapeExcel::Validation.new(options: options))
  end

  context 'without range name' do
    let(:validation) { SequencescapeExcel::Validation.new(options: options) }

    it 'will have some options' do
      expect(validation.options).to eq(options)
    end

    it 'will not have a range name' do
      expect(validation.range_name).to be_nil
    end

    it 'does not add a range' do
      validation.update(range: range)
      expect(validation.formula1).to_not eq(range.absolute_reference)
    end
  end

  context 'with range name' do
    let(:validation) { SequencescapeExcel::Validation.new(options: options, range_name: :a_range) }

    it 'will have a range name' do
      expect(validation.range_name).to eq(:a_range)
    end

    it '#update will set formula1' do
      validation.update(range: range)
      expect(validation.formula1).to eq(range.absolute_reference)
    end

    it 'will be duplicated correctly' do
      dupped = validation.dup
      validation.update(range: range)
      expect(dupped.options).to_not eq(validation.options)
      expect(dupped).to_not be_saved
    end
  end

  context 'with worksheet' do
    let(:worksheet) { Axlsx::Package.new.workbook.add_worksheet }
    let(:range) { build(:range) }
    let(:validation) { SequencescapeExcel::Validation.new(options: options) }

    it 'has some options' do
      expect(validation.options).to eq(options)
    end

    it 'adds validation to the worksheet' do
      validation.update(reference: range.reference, worksheet: worksheet)
      validations = worksheet.data_validation_rules
      expect(validation).to be_saved
      expect(validations.count).to eq(1)
      expect(validations.first.sqref).to eq(range.reference)
    end

    it 'is comparable' do
      validation.update(reference: range.reference, worksheet: worksheet)
      other_validation = SequencescapeExcel::Validation.new(options: options)
      other_validation.update(reference: range.reference, worksheet: worksheet)
      expect(other_validation).to eq(validation)

      other_validation = SequencescapeExcel::Validation.new(options: options.merge(option3: 'value3'))
      other_validation.update(reference: range.reference, worksheet: worksheet)
      expect(other_validation).to_not eq(validation)
    end
  end
end
