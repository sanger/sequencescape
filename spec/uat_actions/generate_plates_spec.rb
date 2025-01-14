# frozen_string_literal: true

require 'rails_helper'

describe UatActions::GeneratePlates do
  context 'with valid options' do
    let(:study) { create(:study, name: 'Test Study') }
    let(:uat_action) { described_class.new(parameters) }
    let(:plate_barcode_1) { build(:plate_barcode) }
    let(:plate_barcode_2) { build(:plate_barcode) }
    let(:plate_barcode_3) { build(:plate_barcode) }

    context 'when creating a single plate' do
      let(:num_samples_per_well) { 1 }
      let(:parameters) do
        {
          plate_purpose_name: PlatePurpose.stock_plate_purpose.name,
          plate_count: 1,
          well_count: 1,
          study_name: study.name,
          well_layout: 'Column',
          number_of_samples_in_each_well: num_samples_per_well
        }
      end
      let(:report) do
        # A report is a hash of key value pairs which get returned to the user.
        # It should include information such as barcodes and identifiers
        { 'plate_0' => plate_barcode_1[:barcode] }
      end

      before { allow(PlateBarcode).to receive(:create_barcode).and_return(plate_barcode_1) }

      it 'can be performed' do
        expect(uat_action.perform).to be true
        expect(uat_action.report['plate_0']).to eq report['plate_0']
        expect(Plate.find_by_barcode(report['plate_0']).wells.first.aliquots.first.study).to eq study
        expect(Plate.find_by_barcode(report['plate_0']).wells.first.aliquots.size).to eq 1
      end

      context 'with multiple samples per well' do
        let(:num_samples_per_well) { 4 }

        it 'can be performed' do
          expect(uat_action.perform).to be true
          expect(Plate.find_by_barcode(report['plate_0']).wells.first.aliquots.size).to eq 4
        end
      end
    end

    context 'when creating multiple plates' do
      let(:parameters) do
        {
          plate_purpose_name: PlatePurpose.stock_plate_purpose.name,
          plate_count: 3,
          well_count: 1,
          study_name: study.name,
          well_layout: 'Column'
        }
      end
      let(:report) do
        # A report is a hash of key value pairs which get returned to the user.
        # It should include information such as barcodes and identifiers
        {
          'plate_0' => plate_barcode_1[:barcode],
          'plate_1' => plate_barcode_2[:barcode],
          'plate_2' => plate_barcode_3[:barcode]
        }
      end

      before do
        allow(PlateBarcode).to receive(:create_barcode).and_return(plate_barcode_1, plate_barcode_2, plate_barcode_3)
      end

      it 'can be performed' do
        expect(uat_action.perform).to be true
        expect(uat_action.report['plate_0']).to eq report['plate_0']
        expect(uat_action.report['plate_1']).to eq report['plate_1']
        expect(uat_action.report['plate_2']).to eq report['plate_2']
      end
    end
  end

  it 'returns a default' do
    expect(described_class.default).to be_a described_class
  end

  describe '#valid?' do
    let(:uat_action) { described_class.new(parameters) }

    describe '#validate_plate_purpose_exists' do
      let(:parameters) { { plate_purpose_name: } }
      let(:error_message) { format(described_class::ERROR_PLATE_PURPOSE_DOES_NOT_EXIST, plate_purpose_name) }

      context 'when the plate purpose does not exist' do
        let(:plate_purpose_name) { 'Invalid Plate Purpose' }

        it 'adds the error message' do
          expect(uat_action.valid?).to be false
          expect(uat_action.errors[:plate_purpose_name]).to include(error_message)
        end
      end

      context 'when the plate purpose exists' do
        let(:plate) { create(:plate) }
        let(:plate_purpose_name) { plate.purpose.name }

        it 'does not add the error message' do
          expect(uat_action.valid?).to be false
          expect(uat_action.errors[:plate_purpose_name]).not_to include(error_message)
        end
      end
    end

    describe '#validate_well_count_is_smaller_than_plate_size' do
      let(:parameters) { { plate_purpose_name:, well_count: } }
      let(:plate) { create(:plate, size: 96) }
      let(:plate_purpose_name) { plate.purpose.name }
      let(:error_message) do
        format(described_class::ERROR_WELL_COUNT_EXCEEDS_PLATE_SIZE, well_count, plate.size, plate_purpose_name)
      end

      context 'when the well count exceeds the plate size' do
        let(:well_count) { plate.size + 1 }

        it 'adds the error message' do
          expect(uat_action.valid?).to be false
          expect(uat_action.errors[:well_count]).to include(error_message)
        end
      end

      context 'when the well count is equal to the plate size' do
        let(:well_count) { plate.size }

        it 'does not add the error message' do
          uat_action.valid? # run validations
          expect(uat_action.errors[:well_count]).not_to include(error_message)
        end
      end
    end

    describe '#validate_study_exists' do
      let(:parameters) { { study_name: } }
      let(:error_message) { format(described_class::ERROR_STUDY_DOES_NOT_EXIST, study_name) }

      context 'when the study exists' do
        let(:study) { create(:study) }
        let(:study_name) { study.name }

        it 'does not add the error message' do
          uat_action.valid? # run validations
          expect(uat_action.errors[:study_name]).not_to include(error_message)
        end
      end

      context 'when the study does not exist' do
        let(:study_name) { 'Invalid Study' }

        it 'adds the error message' do
          expect(uat_action.valid?).to be false
          expect(uat_action.errors[:study_name]).to include(error_message)
        end
      end
    end
  end
end
