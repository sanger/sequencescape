require 'rails_helper'

RSpec.describe SampleManifestExcel::Range, type: :model, sample_manifest_excel: true do

  let(:options) { ['option1', 'option2', 'option3'] }

  it 'should be comparable' do
    attributes = { options: options, first_column: 4, first_row: 5, last_column: 8, last_row: 10, worksheet_name: 'Sheet1' }
    expect(SampleManifestExcel::Range.new(attributes)).to eq(SampleManifestExcel::Range.new(attributes))
    expect(SampleManifestExcel::Range.new(attributes.except(:last_row))).to_not eq(SampleManifestExcel::Range.new(attributes)) 
  end

  context 'with options' do

    let(:range) { SampleManifestExcel::Range.new(options: options, first_row: 4) }

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
      expect(SampleManifestExcel::Range.new(options: options, first_column: 4, first_row: 4).last_column).to eq(6)
    end

    it 'has a first_cell' do
      expect(range.first_cell).to eq(SampleManifestExcel::Cell.new(range.first_row, range.first_column)) 
    end

    it 'has a last_cell' do
      expect(range.last_cell).to eq(SampleManifestExcel::Cell.new(range.last_row, range.last_column))
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
      expect(range.references).to eq({ first_cell_reference: range.first_cell_reference,
                     reference: range.reference, fixed_reference: range.fixed_reference,
                     absolute_reference: range.absolute_reference })
    end
  end

  context 'without first row' do

    let(:range) { SampleManifestExcel::Range.new(options: options) }

    it 'is be valid' do
      expect(range).to_not be_valid
    end

    it 'does not have a first cell' do
      expect(range.first_cell).to be_nil 
    end

    it 'does not have a last cell' do
      expect(range.last_cell).to be_nil 
    end
  end

  context 'without options' do

    let(:range) { SampleManifestExcel::Range.new(first_row: 10, last_row: 15, first_column: 3, last_column: 60) }

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
      expect(range.first_cell).to eq(SampleManifestExcel::Cell.new(range.first_row, range.first_column))
    end

    it 'has a last_cell' do
      expect(range.last_cell).to eq(SampleManifestExcel::Cell.new(range.last_row, range.last_column))
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

      let(:range) { SampleManifestExcel::Range.new(first_row: 15, first_column: 5, last_column: 15) }

      it 'set last row to first row' do
        expect(range.last_row).to eq(15)
      end
    end

    context 'without last column' do

      let(:range) { SampleManifestExcel::Range.new(first_row: 14, last_row: 25, first_column: 33) }

      it 'set last column to first column' do
        expect(range.last_column).to eq(33)
      end
    end

    context 'with worksheet name' do

      let(:range) { SampleManifestExcel::Range.new(first_row: 10, last_row: 15, first_column: 3, last_column: 60, worksheet_name: 'Sheet1') }

      it 'set worksheet name' do
        expect(range.worksheet_name).to eq('Sheet1')
      end

      it 'set absolute reference' do
        expect(range.absolute_reference).to eq("Sheet1!#{range.fixed_reference}")
      end
    end
  end
end
