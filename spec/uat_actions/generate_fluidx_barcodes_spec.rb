# frozen_string_literal: true

require 'rails_helper'

# rubocop:disable RSpec/MultipleExpectations
describe UatActions::GenerateFluidxBarcodes do
  let(:uat_action) { described_class.new(params) }

  describe '.default' do
    let(:uat_action) { described_class.default }

    it 'returns a default instance' do
      expect(uat_action).to be_an_instance_of(described_class)
      expect(uat_action).to be_valid
    end
  end

  describe '#perform' do
    context 'with default instance' do
      let(:uat_action) { described_class.default }

      it 'generates barcodes' do
        expect(uat_action.perform).to be true # Note that this calls the perform method
        expect(uat_action.report['barcodes'].size).to eq uat_action.barcode_count.to_i
        expect(uat_action.report['barcodes'].first).to match(/\A[A-Z]{2}\d{8}\z/)
        expect(uat_action.report['barcodes'].first).to start_with(uat_action.barcode_prefix)
        expect(uat_action.report['barcodes'].first).to end_with(uat_action.barcode_index.to_s)
      end
    end

    context 'with valid options' do
      let(:params) { { barcode_count: 10, barcode_prefix: 'SQ', barcode_index: 1 } }

      # rubocop:disable RSpec/ExampleLength
      it 'generates barcodes' do
        expect(uat_action.perform).to be true
        expect(uat_action.report['barcodes'].size).to eq params[:barcode_count].to_i
        expect(uat_action.report['barcodes']).to all(match(/\A[A-Z]{2}\d{8}\z/))
        expect(uat_action.report['barcodes']).to all(start_with(params[:barcode_prefix]))
        expect(uat_action.report['barcodes'].first).to end_with(params[:barcode_index].to_s) # first index
        expect(uat_action.report['barcodes'].last).to end_with(params[:barcode_count].to_s) # last
      end
      # rubocop:enable RSpec/ExampleLength
    end

    context 'with existing barcodes' do
      let(:params) { { barcode_count: 10, barcode_prefix: 'SQ', barcode_index: 1 } }

      let(:existing_barcodes) do
        # Create 10 FluidX barcodes: SQ00000001 to SQ00000010
        (1..10).map { |index| create(:fluidx, barcode: format('SQ%08d', index)).barcode }
      end

      before do
        existing_barcodes
        # Make generated barcodes predictable.
        allow(uat_action).to receive(:generate_random).and_return('000000')
      end

      it 'generates unique barcodes' do
        expect(uat_action.perform).to be true
        existing_barcodes.each { |existing| expect(uat_action.report['barcodes']).not_to include(existing) }
      end
    end

    context 'with max number of iterations' do
      let(:params) { { barcode_count: 10, barcode_prefix: 'SQ', barcode_index: 1 } }

      before { allow(uat_action).to receive(:filter_barcodes).and_return([]) }

      it 'fails to generate unique barcodes' do
        expect(uat_action.perform).to be false
        expect(uat_action.errors[:base]).to include('Failed to generate unique barcodes')
      end
    end
  end

  describe '#valid?' do
    shared_examples 'an invalid action' do |field, error_message|
      it "is invalid when #{field} is invalid" do
        expect(uat_action).not_to be_valid
        expect(uat_action.errors[field]).to include(error_message)
      end
    end

    context 'with barcode_count not present' do
      let(:params) { { barcode_prefix: 'SQ', barcode_index: 1 } }

      it_behaves_like 'an invalid action', :barcode_count, 'can\'t be blank'
    end

    context 'with barcode_count non-integer' do
      let(:params) { { barcode_count: 'not-an-integer', barcode_prefix: 'SQ', barcode_index: 1 } }

      it_behaves_like 'an invalid action', :barcode_count, 'is not a number'
    end

    context 'with barcode_count smaller than one' do
      let(:params) { { barcode_count: '0', barcode_prefix: 'SQ', barcode_index: 1 } }

      it_behaves_like 'an invalid action', :barcode_count, 'must be greater than 0'
    end

    context 'with barcode_count greater than 96' do
      let(:params) { { barcode_count: '97', barcode_prefix: 'SQ', barcode_index: 1 } }

      it_behaves_like 'an invalid action', :barcode_count, 'must be less than or equal to 96'
    end

    context 'with barcode_prefix not present' do
      let(:params) { { barcode_count: '96', barcode_index: 1 } }

      it_behaves_like 'an invalid action', :barcode_prefix, 'can\'t be blank'
    end

    context 'with barcode_prefix longer than two characters' do
      let(:params) { { barcode_count: '10', barcode_prefix: 'ABC', barcode_index: 1 } }

      it_behaves_like 'an invalid action', :barcode_prefix, 'is the wrong length (should be 2 characters)'
    end

    context 'with barcode_prefix not uppercase' do
      let(:params) { { barcode_count: '10', barcode_prefix: 'bc', barcode_index: 1 } }

      it_behaves_like 'an invalid action', :barcode_prefix, 'only allows two uppercase letters'
    end

    context 'with barcode_index non present' do
      let(:params) { { barcode_count: '10', barcode_prefix: 'SQ' } }

      it_behaves_like 'an invalid action', :barcode_index, 'can\'t be blank'
    end

    context 'with barcode_index non-integer' do
      let(:params) { { barcode_count: '10', barcode_prefix: 'SQ', barcode_index: 'not-an-integer' } }

      it_behaves_like 'an invalid action', :barcode_index, 'is not a number'
    end

    context 'with barcode_index smaller than one' do
      let(:params) { { barcode_count: '10', barcode_prefix: 'SQ', barcode_index: 0 } }

      it_behaves_like 'an invalid action', :barcode_index, 'must be greater than 0'
    end

    context 'with barcode_count less than 901' do
      let(:params) { { barcode_count: '10', barcode_prefix: 'SQ', barcode_index: 901 } }

      it_behaves_like 'an invalid action', :barcode_index, 'must be less than or equal to 900'
    end
  end
end
# rubocop:enable RSpec/MultipleExpectations
