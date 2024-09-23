# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SequencescapeExcel::Range, :sample_manifest, :sample_manifest_excel, type: :model do
  let(:options) { %w[option1 option2 option3] }

  it 'is comparable' do
    attributes = { options:, first_column: 4, first_row: 5, last_column: 8, last_row: 10, worksheet_name: 'Sheet1' }

    # rubocop:todo RSpec/IdenticalEqualityAssertion
    expect(described_class.new(attributes)).to eq(described_class.new(attributes))

    # rubocop:enable RSpec/IdenticalEqualityAssertion
    expect(described_class.new(attributes.except(:last_row))).not_to eq(described_class.new(attributes))
  end

  context 'with static options' do
    let(:range) { described_class.new(options:, first_row: 4) }

    it 'has some options' do
      expect(range.options).to eq(options)
    end

    it 'has a first row' do
      expect(range.first_row).to eq(4)
    end

    it 'sets the first column' do
      expect(range.first_column).to eq(1)
    end

    it 'sets the last column' do
      expect(range.last_column).to eq(3)
      expect(described_class.new(options:, first_column: 4, first_row: 4).last_column).to eq(6)
    end

    it 'has a first_cell' do
      expect(range.first_cell).to eq(SequencescapeExcel::Cell.new(range.first_row, range.first_column))
    end

    it 'has a last_cell' do
      expect(range.last_cell).to eq(SequencescapeExcel::Cell.new(range.last_row, range.last_column))
    end

    it 'has a first cell reference' do
      expect(range.first_cell_reference).to eq(range.first_cell.reference)
    end

    it 'sets the reference' do
      expect(range.reference).to eq("#{range.first_cell.reference}:#{range.last_cell.reference}")
    end

    it 'sets the fixed reference' do
      expect(range.fixed_reference).to eq("#{range.first_cell.fixed}:#{range.last_cell.fixed}")
    end

    it '#references should return first_cell reference, reference, fixed_reference and absolute_reference' do
      expect(range.references).to eq(
        first_cell_reference: range.first_cell_reference,
        reference: range.reference,
        fixed_reference: range.fixed_reference,
        absolute_reference: range.absolute_reference
      )
    end

    it 'is static, not dynamic' do
      expect(range).to be_static
      expect(range).not_to be_dynamic
    end
  end

  context 'with dynamic options' do
    # Ensure we have at least one option.
    before { create :library_type }

    let!(:original_option_size) { LibraryType.count }
    let(:attributes) { { name: 'library_type', identifier: :name, scope: :alphabetical, first_row: 4 } }
    let(:range) { described_class.new(attributes) }

    it 'has identifier, scope, options' do
      assert range.identifier
      assert range.scope
      expect(range.options.count).to eq(original_option_size)
    end

    it 'has a first row' do
      expect(range.first_row).to eq(4)
    end

    it 'sets the first column' do
      expect(range.first_column).to eq(1)
    end

    it 'sets the last column' do
      expect(range.last_column).to eq(original_option_size)
      expect(described_class.new(attributes.merge(first_column: 4)).last_column).to eq(3 + original_option_size)
    end

    it 'has a first_cell' do
      expect(range.first_cell).to eq(SequencescapeExcel::Cell.new(range.first_row, range.first_column))
    end

    it 'has a last_cell' do
      expect(range.last_cell).to eq(SequencescapeExcel::Cell.new(range.last_row, range.last_column))
    end

    it 'has a first cell reference' do
      expect(range.first_cell_reference).to eq(range.first_cell.reference)
    end

    it 'sets the reference' do
      expect(range.reference).to eq("#{range.first_cell.reference}:#{range.last_cell.reference}")
    end

    it 'sets the fixed reference' do
      expect(range.fixed_reference).to eq("#{range.first_cell.fixed}:#{range.last_cell.fixed}")
    end

    it '#references should return first_cell reference, reference, fixed_reference and absolute_reference' do
      expect(range.references).to eq(
        {
          first_cell_reference: range.first_cell_reference,
          reference: range.reference,
          fixed_reference: range.fixed_reference,
          absolute_reference: range.absolute_reference
        }
      )
    end

    it 'knows it is dynamic' do
      expect(range).not_to be_static
      expect(range).to be_dynamic
    end

    it 'adjusts to changes in option number' do
      previous_last_cell = range.last_cell.column
      create :library_type, name: 'Other'
      expect(range.last_column).to eq(original_option_size + 1)
      expect(range.last_cell.column).to eq(previous_last_cell.next)
    end
  end

  context 'with dynamic options and parameters' do
    let(:attributes) do
      { name: 'library_type', identifier: :name, scope: [:from_record_loaders, '001_long_read'], first_row: 4 }
    end
    let(:range) { described_class.new(attributes) }

    it 'passes the options to the scope' do
      allow(LibraryType).to receive(:from_record_loaders).with('001_long_read').and_return(LibraryType.all)
      range.options
    end
  end

  context 'without first row' do
    let(:range) { described_class.new(options:) }

    it 'is be valid' do
      expect(range).not_to be_valid
    end

    it 'does not have a first cell' do
      expect(range.first_cell).to be_nil
    end

    it 'does not have a last cell' do
      expect(range.last_cell).to be_nil
    end
  end

  context 'without options' do
    let(:range) { described_class.new(first_row: 10, last_row: 15, first_column: 3, last_column: 60) }

    it 'has some empty options' do
      expect(range.options).to be_empty
    end

    it 'has a first row' do
      expect(range.first_row).to eq(10)
    end

    it 'has a first column' do
      expect(range.first_column).to eq(3)
    end

    it 'has a last column' do
      expect(range.last_column).to eq(60)
    end

    it 'has a first_cell' do
      expect(range.first_cell).to eq(SequencescapeExcel::Cell.new(range.first_row, range.first_column))
    end

    it 'has a last_cell' do
      expect(range.last_cell).to eq(SequencescapeExcel::Cell.new(range.last_row, range.last_column))
    end

    it 'sets the fixed_reference' do
      expect(range.reference).to eq("#{range.first_cell.reference}:#{range.last_cell.reference}")
    end

    it 'sets the fixed reference' do
      expect(range.fixed_reference).to eq("#{range.first_cell.fixed}:#{range.last_cell.fixed}")
    end

    it 'has an absolute reference' do
      expect(range.absolute_reference).to eq(range.fixed_reference)
    end

    it '#set_worksheet_name should set worksheet name and modify absolute reference' do
      range.set_worksheet_name 'Sheet1'
      expect(range.worksheet_name).to eq('Sheet1')
      expect(range.absolute_reference).to eq("#{range.worksheet_name}!#{range.fixed_reference}")
    end

    context 'without last row' do
      let(:range) { described_class.new(first_row: 15, first_column: 5, last_column: 15) }

      it 'set last row to first row' do
        expect(range.last_row).to eq(15)
      end
    end

    context 'without last column' do
      let(:range) { described_class.new(first_row: 14, last_row: 25, first_column: 33) }

      it 'set last column to first column' do
        expect(range.last_column).to eq(33)
      end
    end

    context 'with worksheet name' do
      let(:range) do
        described_class.new(first_row: 10, last_row: 15, first_column: 3, last_column: 60, worksheet_name: 'Sheet1')
      end

      it 'set worksheet name' do
        expect(range.worksheet_name).to eq('Sheet1')
      end

      it 'set absolute reference' do
        expect(range.absolute_reference).to eq("Sheet1!#{range.fixed_reference}")
      end
    end
  end
end
