# frozen_string_literal: true

require 'rails_helper'

describe UatActions::GeneratePlateVolumes do
  let(:plate) { create(:plate_with_untagged_wells, sample_count: 3) }
  let(:plate_barcode) { plate.barcodes.first.barcode }
  let(:uat_action) { described_class.new(parameters) }
  let!(:performed_action) { uat_action.perform }

  context 'with valid options' do
    let(:report) do
      # A report is a hash of key value pairs which get returned to the user.
      # It should include information such as barcodes and identifiers
      { 'number_well_volumes_written' => 3 }
    end

    let(:parameters) { { plate_barcode: plate_barcode, minimum_volume: 0, maximum_volume: 30 } }

    it 'can be performed' do
      expect(performed_action).to be true
    end

    it 'generates the correct report' do
      expect(uat_action.report).to eq report
    end

    it 'creates the correct number of QC results' do
      expect(plate.wells.map(&:qc_results).size).to eq 3
    end

    it 'sets the correct assay type for the first QC result' do
      expect(plate.wells.first.qc_results.first.assay_type).to eq 'UAT_Testing'
    end

    it 'sets the volumes to be within the specified range' do
      expect(plate.wells.map { |well| well.qc_results.first.value.to_f }).to all(be_between(0, 30))
    end
  end

  context 'with default options' do
    let(:parameters) { { plate_barcode: } }

    it 'returns an instance of described_class' do
      expect(described_class.default).to be_a described_class
    end

    it 'has a nil plate_barcode' do
      expect(described_class.default.plate_barcode).to be_nil
    end

    it 'has a minimum_volume of 0' do
      expect(described_class.default.minimum_volume).to eq 0
    end

    it 'has a maximum_volume of 100' do
      expect(described_class.default.maximum_volume).to eq 100
    end
  end

  context 'with invalid options' do
    let(:parameters) { { plate_barcode: plate_barcode, minimum_volume: 110, maximum_volume: 10 } }
    let!(:saved_action) { uat_action.save }

    it 'has a minimum_volume of 110' do
      expect(uat_action.minimum_volume).to eq 110
    end

    it 'has a maximum_volume of 10' do
      expect(uat_action.maximum_volume).to eq 10
    end

    it 'is invalid' do
      expect(uat_action.valid?).to be false
    end

    it 'can not be saved' do
      expect(saved_action).to be false
    end

    it 'adds an error' do
      expect(uat_action.errors.full_messages).to include(
        'Maximum volume needs to be greater than or equal to minimum volume'
      )
    end
  end

  context 'with equal minimum and maximum volumes' do
    let(:parameters) { { plate_barcode: plate_barcode, minimum_volume: 10, maximum_volume: 10 } }

    it 'can be performed' do
      expect(performed_action).to be true
    end

    it 'generates the correct report' do
      expect(uat_action.report).to eq('number_well_volumes_written' => 3)
    end

    it 'creates the correct number of QC results' do
      expect(plate.wells.map(&:qc_results).size).to eq 3
    end

    it 'sets the volumes to be within the specified range' do
      expect(plate.wells.map { |well| well.qc_results.first.value.to_f }).to all(eq 10)
    end
  end
end
