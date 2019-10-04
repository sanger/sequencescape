# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SequencescapeExcel::Column, type: :model, sample_manifest_excel: true, sample_manifest: true do
  let(:range_list)  { build(:range_list, ranges_data: { FactoryBot.attributes_for(:validation)[:range_name] => FactoryBot.attributes_for(:range) }) }
  let(:worksheet)   { Axlsx::Workbook.new.add_worksheet }
  let(:options)     do
    { heading: 'PUBLIC NAME', name: :public_name, type: :string, value: 10, number: 125, attribute: :barcode,
      validation: FactoryBot.attributes_for(:validation),
      conditional_formattings: { simple: FactoryBot.attributes_for(:conditional_formatting), complex: FactoryBot.attributes_for(:conditional_formatting_with_formula) } }
  end

  it 'must have a heading' do
    expect(described_class.new(options).heading).to eq(options[:heading])
  end

  it 'is not valid without a heading' do
    expect described_class.new(options.except(:heading)).valid?
  end

  it 'must have a name' do
    expect(described_class.new(options).name).to eq(options[:name])
  end

  it 'is not valid without a name' do
    expect(described_class.new(options.except(:name))).not_to be_valid
  end

  it 'has a type' do
    expect(described_class.new(options).type).to eq(options[:type])
  end

  it 'has a value' do
    expect(described_class.new(options).value).to eq(options[:value])
    expect(described_class.new(options.except(:value)).value).to be_nil
  end

  it 'is comparable' do
    expect(described_class.new(options)).to eq(described_class.new(options))
    expect(described_class.new(options.merge(heading: 'SOME OTHER NAME'))).not_to eq(described_class.new(options))
  end

  it 'has an attribute value' do
    detail = { barcode: 'barcode', sanger_id: 'sanger_id', position: 'position' }
    expect(described_class.new(options).attribute_value(detail)).to eq(detail[:barcode])
    expect(described_class.new(options.except(:attribute)).attribute_value(detail)).to eq(options[:value])
    expect(described_class.new(options.except(:value, :attribute)).attribute_value(detail)).to be_nil
  end

  it 'has a number' do
    expect(described_class.new(options).number).to eq(options[:number])
  end

  it 'can indicate whether the column is related to sample metadata' do
    expect(described_class.new(options)).not_to be_metadata_field
    expect(described_class.new(options.merge(heading: 'DONOR ID', name: :donor_id))).to be_metadata_field
  end

  it 'can indicate whether the column is a specialised field and returns the constant' do
    column = described_class.new(options)
    expect(column).not_to be_specialised_field

    column = described_class.new(options.merge(heading: 'INSERT SIZE FROM', name: :insert_size_from))
    expect(column).to be_specialised_field
    expect(column.specialised_field).to eq(SequencescapeExcel::SpecialisedField::InsertSizeFrom)
  end

  it 'can update the sample metadata if it is a sample metadata field' do
    column = described_class.new(options.merge(heading: 'DONOR ID', name: :donor_id))
    metadata = Sample::Metadata.new
    column.update_metadata(metadata, '1234')
    expect(metadata.donor_id).to eq('1234')
  end

  context 'with no validation' do
    let(:column) { described_class.new(options.except(:validation)) }

    it 'will have an empty validation' do
      expect(column.validation).to be_empty
    end

    it 'will have a range name' do
      expect(column.range_name).to be_present
    end

    it 'will update without any problems' do
      expect(column.update(27, 150, range_list, worksheet)).to be_updated
    end
  end

  context 'with no conditional formattings' do
    let(:column) { described_class.new(options.except(:conditional_formattings)) }

    it 'will have empty conditional formattings' do
      expect(column.conditional_formattings).to be_empty
    end

    it 'updates without any problems' do
      expect(column.update(27, 150, range_list, worksheet)).to be_updated
    end
  end

  describe '#update with validation and formattings' do
    let(:worksheet) { Axlsx::Workbook.new.add_worksheet }
    let(:column) { described_class.new(options) }
    let(:range) { SequencescapeExcel::Range.new(first_column: column.number, first_row: 27, last_row: 150) }

    before do
      column.update(27, 150, range_list, worksheet)
    end

    it 'will update' do
      expect(column).to be_updated
    end

    it 'sets the reference' do
      expect(column.range).to eq(range)
    end

    it 'modifies the validation' do
      expect(column.validation.formula1).to eq(range_list.find_by(column.range_name).absolute_reference)
      expect(worksheet.data_validation_rules).to be_all { |rule| rule.sqref == column.range.reference }
      expect(column.validation).to be_saved
    end

    it 'modifies the conditional formatting' do
      expect(column.conditional_formattings.count).to eq(options[:conditional_formattings].length)
      expect(column.conditional_formattings).to be_saved
    end

    it 'duplicates correctly' do
      column = described_class.new(options)
      dupped = column.dup
      column.update(27, 150, range_list, worksheet)
      expect(dupped.range).not_to eq(range)
      expect(dupped.validation).not_to be_saved
      expect(dupped.conditional_formattings).not_to be_saved
    end
  end

  # TODO: Need to improve way keys are found to reduce brittleness of tests.
  # would break if column names changed.
  context 'argument builder' do
    include SequencescapeExcel::Helpers

    let(:folder) { File.join('spec', 'data', 'sample_manifest_excel', 'extract') }
    let(:columns) { load_file(folder, 'columns') }
    let(:defaults) { SequencescapeExcel::ConditionalFormattingDefaultList.new(load_file(folder, 'conditional_formattings')) }

    it 'inserts the name of the column' do
      arguments = described_class.build_arguments(columns.values.first, columns.keys.first, defaults)
      expect(arguments[:name]).to eq(columns.keys.first)
    end

    it 'still has the validations' do
      key = columns.find { |_k, v| v[:validation].present? }.first
      expect(described_class.build_arguments(columns[key], key, defaults)[:validation]).to be_present
    end

    it 'combines the conditional formattings correctly' do
      arguments = described_class.build_arguments(columns[:gender], 'gender', defaults)
      expect(arguments[:conditional_formattings].length).to eq(columns[:gender][:conditional_formattings].length)
      arguments[:conditional_formattings].each do |k, _conditional_formatting|
        expect(arguments[:conditional_formattings][k]).to eq(defaults.find_by(:type, k).combine(columns[:gender][:conditional_formattings][k]))
      end
    end

    it 'combines the conditional formattings correctly if there is a formula' do
      arguments = described_class.build_arguments(columns[:supplier_name], 'supplier_name', defaults)
      expect(arguments[:conditional_formattings][:len][:formula]).to eq(defaults.find(:len).combine(columns[:supplier_name][:conditional_formattings][:len])[:formula])
    end
  end
end
