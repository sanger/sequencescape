# frozen_string_literal: true

require 'rails_helper'

describe UatActions::TestSubmission do
  context 'valid options' do
    before { expect(PlateBarcode).to receive(:create_barcode).and_return(first_plate_barcode) }

    let(:submission_template) { create(:limber_wgs_submission_template) }
    let(:primer_panel) { create(:primer_panel) }
    let(:parameters) { { submission_template_name: submission_template.name } }
    let(:uat_action) { described_class.new(parameters) }
    let(:first_plate_barcode) { build(:plate_barcode) }
    let(:report) do
      # A report is a hash of key value pairs which get returned to the user.
      # It should include information such as barcodes and identifiers
      { 'plate_barcode_0' => first_plate_barcode[:barcode] }
    end

    it 'can be performed' do
      expect(uat_action.perform).to be true
      expect(uat_action.report['plate_barcode_0']).to eq report['plate_barcode_0']
      expect(uat_action.report['submission_id']).to be_a Integer
    end

    context 'with optional plate purpose supplied' do
      let(:parameters) do
        {
          submission_template_name: submission_template.name,
          plate_purpose_name: PlatePurpose.stock_plate_purpose.name
        }
      end

      it 'can be performed' do
        expect(uat_action.perform).to be true
        expect(uat_action.report['plate_barcode_0']).to eq report['plate_barcode_0']
        expect(uat_action.report['submission_id']).to be_a Integer
      end
    end

    context 'with optional library type supplied' do
      let(:parameters) { { submission_template_name: submission_template.name, library_type_name: 'Standard' } }

      it 'can be performed' do
        expect(uat_action.perform).to be true
        expect(uat_action.report['plate_barcode_0']).to eq report['plate_barcode_0']
        expect(uat_action.report['submission_id']).to be_a Integer
        expect(uat_action.report['library_type']).to eq 'Standard'
      end
    end

    context 'with optional primer panel supplied' do
      let(:parameters) do
        {
          submission_template_name: submission_template.name,
          library_type_name: 'Standard',
          primer_panel_name: 'Primer Panel 1'
        }
      end

      it 'can be performed' do
        expect(uat_action.perform).to be true
        expect(uat_action.report['plate_barcode_0']).to eq report['plate_barcode_0']
        expect(uat_action.report['submission_id']).to be_a Integer
        expect(uat_action.report['library_type']).to eq 'Standard'
        expect(uat_action.report['primer_panel']).to eq 'Primer Panel 1'
      end
    end

    context 'with optional number of wells with samples supplied' do
      let(:parameters) { { submission_template_name: submission_template.name, number_of_wells_with_samples: '2' } }

      it 'can be performed' do
        expect(uat_action.perform).to be true
        expect(uat_action.report['plate_barcode_0']).to eq report['plate_barcode_0']
        expect(uat_action.report['submission_id']).to be_a Integer
        expect(uat_action.report['number_of_wells_with_samples']).to be_a Integer
      end
    end

    context 'with optional number of wells to submit supplied' do
      let(:parameters) { { submission_template_name: submission_template.name, number_of_wells_to_submit: '2' } }

      it 'can be performed' do
        expect(uat_action.perform).to be true
        expect(uat_action.report['plate_barcode_0']).to eq report['plate_barcode_0']
        expect(uat_action.report['number_of_wells_to_submit']).to be_a Integer
      end
    end

    context 'with optional number of samples per well supplied' do
      let(:parameters) { { submission_template_name: submission_template.name, number_of_samples_in_each_well: '2' } }

      it 'can be performed' do
        expect(uat_action.perform).to be true
        expect(uat_action.report['plate_barcode_0']).to eq report['plate_barcode_0']
        expect(uat_action.report['number_of_samples_in_each_well']).to be_a Integer
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

    describe '#validate_plate_exists' do
      let(:parameters) { { plate_barcode: } }
      let(:error_message) { format(described_class::ERROR_PLATE_DOES_NOT_EXIST, plate_barcode) }

      context 'when the plate does not exist' do
        let(:plate_barcode) { 'Invalid Plate Barcode' }

        it 'adds the error message' do
          expect(uat_action.valid?).to be false
          expect(uat_action.errors[:plate_barcode]).to include(error_message)
        end
      end

      context 'when the plate purpose exists' do
        let(:plate) { create(:plate) }
        let(:plate_barcode) { plate.human_barcode }

        it 'does not add the error message' do
          uat_action.valid? # run validations
          expect(uat_action.errors[:plate_barcode]).not_to include(error_message)
        end
      end
    end

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
          uat_action.valid? # run validations
          expect(uat_action.errors[:plate_purpose_name]).not_to include(error_message)
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

    describe '#validate_primer_panel_exists' do
      let(:parameters) { { primer_panel_name: } }
      let(:error_message) { format(described_class::ERROR_PRIMER_PANEL_DOES_NOT_EXIST, primer_panel_name) }

      context 'when the primer panel does not exist' do
        let(:primer_panel_name) { 'Invalid Primer Panel' }

        it 'adds the error message' do
          expect(uat_action.valid?).to be false
          expect(uat_action.errors[:primer_panel_name]).to include(error_message)
        end
      end

      context 'when the primer panel exists' do
        let(:primer_panel) { create(:primer_panel) }
        let(:primer_panel_name) { primer_panel.name }

        it 'does not add the error message' do
          uat_action.valid? # run validations
          expect(uat_action.errors[:primer_panel_name]).not_to include(error_message)
        end
      end
    end
  end
end
