# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SequencescapeExcel::Validation, type: :model, sample_manifest_excel: true, sample_manifest: true do
  let(:options) { { option1: 'value1', option2: 'value2', type: :whole, formula1: 'smth' } }
  let(:range) { build(:range) }

  it 'is not valid without options' do
    expect(described_class.new).not_to be_valid
  end

  it 'is comparable' do
    expect(described_class.new(options: options)).to eq(described_class.new(options: options))
    expect(described_class.new(options: options.except(:formula1))).not_to eq(described_class.new(options: options))
  end

  context 'without range name' do
    let(:validation) { described_class.new(options: options) }

    it 'will have some options' do
      expect(validation.options).to eq(options)
    end

    it 'will not have a range name' do # rubocop:todo RSpec/AggregateExamples
      expect(validation.range_name).to be_nil
    end

    it 'does not add a range' do
      validation.update(range: range)
      expect(validation.formula1).not_to eq(range.absolute_reference)
    end
  end

  context 'with range name' do
    let(:validation) { described_class.new(options: options, range_name: :a_range) }

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
      expect(dupped.options).not_to eq(validation.options)
      expect(dupped).not_to be_saved
    end
  end

  context 'with worksheet' do
    let(:worksheet) { Axlsx::Package.new.workbook.add_worksheet }
    let(:range) { build(:range) }
    let(:validation) { described_class.new(options: options) }

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
      other_validation = described_class.new(options: options)
      other_validation.update(reference: range.reference, worksheet: worksheet)
      expect(other_validation).to eq(validation)

      other_validation = described_class.new(options: options.merge(option3: 'value3'))
      other_validation.update(reference: range.reference, worksheet: worksheet)
      expect(other_validation).not_to eq(validation)
    end
  end
end
