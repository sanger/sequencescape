# frozen_string_literal: true

require 'rails_helper'

describe UatActions::TubeSubmission do
  context 'with valid options' do
    let(:tube) { create(:sample_tube, purpose: create(:sample_tube_purpose)) }
    let(:tube_barcode) { tube.barcodes.last.barcode }
    let(:submission_template) { create(:pbmc_pooling_submission_template) }
    let(:parameters) { { submission_template_name: submission_template.name, tube_barcodes: tube_barcode } }
    let(:uat_action) { described_class.new(parameters) }
    let(:report) do
      # A report is a hash of key value pairs which get returned to the user.
      # It should include information such as barcodes and identifiers
      { 'tube_barcodes' => [tube_barcode] }
    end

    it 'can be performed' do
      expect(uat_action.perform).to be true
      expect(uat_action.report['tube_barcodes']).to eq report['tube_barcodes']
      expect(uat_action.report['submission_id']).to be_a Integer
    end

    context 'with optional library type supplied' do
      let(:parameters) do
        {
          submission_template_name: submission_template.name,
          tube_barcodes: tube_barcode,
          library_type_name: 'Standard'
        }
      end

      it 'can be performed' do
        expect(uat_action.perform).to be true
        expect(uat_action.report['tube_barcodes']).to eq report['tube_barcodes']
        expect(uat_action.report['submission_id']).to be_a Integer
        expect(uat_action.report['library_type']).to eq 'Standard'
      end
    end

    context 'with optional number of pools supplied' do
      let(:number_of_pools) { 2 }
      let(:parameters) do
        {
          submission_template_name: submission_template.name,
          tube_barcodes: tube_barcode,
          number_of_pools: number_of_pools
        }
      end

      it 'can be performed' do
        expect(uat_action.perform).to be true
        expect(uat_action.report['tube_barcodes']).to eq report['tube_barcodes']
        expect(uat_action.report['submission_id']).to be_a Integer
        expect(uat_action.report['number_of_pools']).to eq number_of_pools
      end
    end

    context 'with optional cells per chip well supplied' do
      let(:num_cells) { 20_000 }
      let(:parameters) do
        {
          submission_template_name: submission_template.name,
          tube_barcodes: tube_barcode,
          cells_per_chip_well: num_cells
        }
      end

      it 'can be performed' do
        expect(uat_action.perform).to be true
        expect(uat_action.report['tube_barcodes']).to eq report['tube_barcodes']
        expect(uat_action.report['submission_id']).to be_a Integer
        expect(uat_action.report['cells_per_chip_well']).to eq num_cells
      end
    end
  end

  it 'returns a default' do
    expect(described_class.default).to be_a described_class
  end

  describe '#valid?' do
    let(:uat_action) { described_class.new(parameters) }

    describe '#validate_submission_template_exists' do
      let(:parameters) { { submission_template_name: } }
      let(:error_message) do
        format(described_class::ERROR_SUBMISSION_TEMPLATE_DOES_NOT_EXIST, submission_template_name)
      end

      context 'when the submission template does not exist' do
        let(:submission_template_name) { 'Invalid Submission Template' }

        it 'adds the error message' do
          expect(uat_action.valid?).to be false
          expect(uat_action.errors[:submission_template_name]).to include(error_message)
        end
      end

      context 'when the submission template exists' do
        let(:submission_template) { create(:submission_template) }
        let(:submission_template_name) { submission_template.name }

        it 'does not add the error message' do
          uat_action.valid? # run validations
          expect(uat_action.errors[:submission_template_name]).not_to include(error_message)
        end
      end
    end

    describe '#validate_tubes_exist' do
      let(:parameters) { { tube_barcodes: } }
      let(:error_message) do
        barcodes = tube_barcodes_array.select { |barcode| barcode.start_with?('INVALID') }.join(', ')
        format(described_class::ERROR_TUBES_DO_NOT_EXIST, barcodes)
      end

      context 'when the tubes do not exist' do
        # Testing valid and invalid barcodes together.
        let(:tubes) { [create(:sample_tube)] }
        let(:tube_barcodes_array) { %w[INVALID-1 INVALID-2] + tubes.map(&:human_barcode) }
        let(:tube_barcodes) { tube_barcodes_array.join('\n') }

        it 'adds the error message' do
          expect(uat_action.valid?).to be false
          expect(uat_action.errors[:tube_barcodes]).to include(error_message)
        end
      end
    end

    describe '#validate_library_type_exists' do
      let(:parameters) { { library_type_name: } }
      let(:error_message) { format(described_class::ERROR_LIBRARY_TYPE_DOES_NOT_EXIST, library_type_name) }

      context 'when the library type does not exist' do
        let(:library_type_name) { 'Invalid Library Type' }

        it 'adds the error message' do
          expect(uat_action.valid?).to be false
          expect(uat_action.errors[:library_type_name]).to include(error_message)
        end
      end

      context 'when the library type exists' do
        let(:library_type) { create(:library_type) }
        let(:library_type_name) { library_type.name }

        it 'does not add the error message' do
          uat_action.valid? # run validations
          expect(uat_action.errors[:library_type_name]).not_to include(error_message)
        end
      end
    end
  end
end
