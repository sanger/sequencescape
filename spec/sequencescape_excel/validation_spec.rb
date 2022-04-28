# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SequencescapeExcel::Validation, type: :model, sample_manifest_excel: true, sample_manifest: true do
  let(:options) { { option1: 'value1', option2: 'value2', type: :whole, formula1: 'smth' }.freeze }
  let(:range) { build(:range) }
  let(:worksheet) { instance_double(Axlsx::Worksheet, add_data_validation: true) }

  it 'is not valid without options' do
    expect(described_class.new).not_to be_valid
  end

  it 'is comparable' do
    # We are explicitly checking that comparable non-identical object show equality
    # rubocop:disable RSpec/IdenticalEqualityAssertion
    expect(described_class.new(options: options)).to eq(described_class.new(options: options))

    # rubocop:enable RSpec/IdenticalEqualityAssertion

    expect(described_class.new(options: options.except(:formula1))).not_to eq(described_class.new(options: options))
  end

  context 'without range name' do
    let(:validation) { described_class.new(options: options) }

    it 'will have some options' do
      expect(validation.options).to eq(options)
    end

    it 'will not have a range name' do
      expect(validation.range_name).to be_nil
    end

    it '#does not add a range' do
      expect(worksheet).to receive(:add_data_validation).with('N10:N30', **options)
      validation.update(range: range, worksheet: worksheet, reference: 'N10:N30')
    end
  end

  context 'with range name' do
    let(:validation) { described_class.new(options: options, range_name: :a_range) }

    it 'will have a range name' do
      expect(validation.range_name).to eq(:a_range)
    end

    it '#update will set formula1' do
      expect(worksheet).to receive(:add_data_validation).with('N10:N30', **options, formula1: range.absolute_reference)
      validation.update(range: range, worksheet: worksheet, reference: 'N10:N30')
    end
  end

  context 'with a custom formula' do
    let(:options) { { type: :custom, formula1: 'AND(A1>5,A1<10)' } }
    let(:validation) { described_class.new(options: options) }

    it 'sends and escaped formula to the worksheet' do
      expect(worksheet).to receive(:add_data_validation).with(
        'N10:N30',
        type: :custom,
        formula1: 'AND(N10&gt;5,N10&lt;10)'
      )
      validation.update(reference: 'N10:N30', worksheet: worksheet)
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
