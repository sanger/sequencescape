# frozen_string_literal: true

require 'rails_helper'

describe UatActions::GeneratePlateConcentrations do
  let(:plate) { create(:plate_with_untagged_wells, sample_count: 3) }
  let(:plate_barcode) { plate.barcodes.first.barcode }
  let(:uat_action) { described_class.new(parameters) }
  let!(:saved_action) { uat_action.save }

  context 'with default options' do
    let(:parameters) { {} }

    it 'returns a default' do
      expect(described_class.default).to be_a described_class
    end

    it 'has a nil plate_barcode' do
      expect(described_class.default.plate_barcode).to be_nil
    end

    it 'has a minimum_concentration of 0' do
      expect(described_class.default.minimum_concentration).to eq 0
    end

    it 'has a maximum_concentration of 100' do
      expect(described_class.default.maximum_concentration).to eq 100
    end

    it 'has a concentration_units of ng/ul' do
      expect(described_class.default.concentration_units).to eq 'ng/ul'
    end
  end

  context 'with valid options' do
    let(:report) do
      # A report is a hash of key value pairs which get returned to the user.
      # It should include information such as barcodes and identifiers
      { 'number_well_concentrations_written' => 3 }
    end

    context 'when ng per ul concentrations' do
      let(:parameters) do
        {
          plate_barcode: plate_barcode,
          concentration_units: 'ng/ul',
          minimum_concentration: 0,
          maximum_concentration: 30
        }
      end

      it 'can be saved' do
        expect(saved_action).to be true
        expect(uat_action.report).to eq report
        expect(plate.wells.map(&:qc_results).size).to eq 3
        expect(plate.wells.first.qc_results.first.assay_type).to eq 'UAT_Testing'
      end
    end

    context 'when nM concentrations' do
      let(:parameters) do
        { plate_barcode: plate_barcode, concentration_units: 'nM', minimum_concentration: 0, maximum_concentration: 30 }
      end

      it 'can be saved' do
        expect(saved_action).to be true
        expect(uat_action.report).to eq report
        expect(plate.wells.map(&:qc_results).size).to eq 3
        expect(plate.wells.first.qc_results.first.assay_type).to eq 'UAT_Testing'
      end
    end
  end

  context 'with invalid options' do
    let(:parameters) do
      {
        plate_barcode: plate_barcode,
        concentration_units: 'ng/ul',
        minimum_concentration: 30,
        maximum_concentration: 10
      }
    end

    it 'has a minimum_concentration of 30' do
      expect(uat_action.minimum_concentration).to eq 30
    end

    it 'has a maximum_concentration of 10' do
      expect(uat_action.maximum_concentration).to eq 10
    end

    it 'is invalid' do
      expect(uat_action.valid?).to be false
    end

    it 'can not be saved' do
      expect(saved_action).to be false
    end

    it 'adds an error' do
      expect(uat_action.errors.full_messages).to include(
        'Maximum concentration needs to be greater than or equal to minimum concentration'
      )
    end
  end

  context 'with equal minimum and maximum concentrations' do
    let(:parameters) do
      {
        plate_barcode: plate_barcode,
        concentration_units: 'ng/ul',
        minimum_concentration: 10,
        maximum_concentration: 10
      }
    end

    it 'can be saved' do
      expect(saved_action).to be true
    end

    it 'generates the correct report' do
      expect(uat_action.report).to eq('number_well_concentrations_written' => 3)
    end

    it 'creates the correct number of QC results' do
      expect(plate.wells.map(&:qc_results).size).to eq 3
    end

    it 'sets the concentrations to be within the specified range' do
      expect(plate.wells.map { |well| well.qc_results.first.value.to_f }).to all(eq 10)
    end
  end
end
