# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PhiX::SpikedBuffer, type: :model, phi_x: true do
  subject { build :phi_x_spiked_buffer, custom_options }

  context 'with suitable options' do
    let(:custom_options) { {} } # Fallback to factory defaults

    it { is_expected.to be_valid }
  end

  context 'with no name' do
    let(:custom_options) { { name: '' } }

    it { is_expected.not_to be_valid }
  end

  [0, -2, 'two'].each do |positive_float|
    context "with the invalid concentration #{positive_float}" do
      let(:custom_options) { { concentration: positive_float } }

      it { is_expected.not_to be_valid }
    end

    context "with the invalid volume #{positive_float}" do
      let(:custom_options) { { volume: positive_float } }

      it { is_expected.not_to be_valid }
    end
  end

  [0, -2, 'two', 1.5].each do |invalid_number|
    context "with the invalid number #{invalid_number}" do
      let(:custom_options) { { number: invalid_number } }

      it { is_expected.not_to be_valid }
    end
  end

  context 'with an unknown barcode' do
    let(:custom_options) { { parent_barcode: 'UNKNOWN', parent: nil } }

    it { is_expected.not_to be_valid }
  end

  context 'with a non-PhiX containing parent' do
    let(:parent) { create :library_tube }
    let(:custom_options) { { parent_barcode: parent.machine_barcode, parent: nil } }

    it { is_expected.not_to be_valid }
  end

  describe '#save' do
    context 'with valid data' do
      subject(:save) { phi_x_spiked_buffer.save }

      let(:parent) { create :phi_x_stock_tube }
      let(:phi_x_spiked_buffer) do
        build :phi_x_spiked_buffer,
              name: 'Example',
              parent_barcode: parent.human_barcode,
              parent: nil,
              concentration: '0.8',
              volume: '10',
              number: 2
      end

      before { save }

      it { is_expected.to be true }

      it 'generates tubes according to the number supplied' do # rubocop:todo RSpec/AggregateExamples
        expect(phi_x_spiked_buffer.created_spiked_buffers).to have(2).items
      end

      it 'generates PhiX SpikedBuffer tubes' do # rubocop:todo RSpec/AggregateExamples
        expect(phi_x_spiked_buffer.created_spiked_buffers).to all be_a SpikedBuffer
        expect(phi_x_spiked_buffer.created_spiked_buffers).to all have_attributes(purpose: PhiX.spiked_buffer_purpose)
      end

      it 'names tubes appropriately' do # rubocop:todo RSpec/AggregateExamples
        expect(phi_x_spiked_buffer.created_spiked_buffers).to all have_attributes(name: a_string_starting_with('Example #'))
      end

      it 'sets the concentration and volume' do # rubocop:todo RSpec/AggregateExamples
        expect(phi_x_spiked_buffer.created_spiked_buffers).to all have_attributes(concentration: 0.8, volume: 10)
      end

      it 'generates an aliquot in each tube' do
        phi_x_spiked_buffer.created_spiked_buffers.each do |tube|
          expect(tube.aliquots).to have(1).items
        end
      end

      it 'generates an aliquot which match the parent' do
        phi_x_spiked_buffer.created_spiked_buffers.each do |tube|
          expect(tube.aliquots).to all have_attributes(sample: parent.aliquots.first.sample, tag: parent.aliquots.first.tag)
        end
      end

      it 'records the parent' do
        phi_x_spiked_buffer.created_spiked_buffers.each do |tube|
          expect(tube.parents).to all eq parent
        end
      end
    end

    context 'with invalid data' do
      let(:phi_x_spiked_buffer) { build :phi_x_spiked_buffer, number: -2 }

      it 'returns false' do
        expect(phi_x_spiked_buffer.save).to eq false
      end
    end
  end

  describe '#tags' do
    let(:phi_x_spiked_buffer) do
      build :phi_x_spiked_buffer,
            name: 'Example',
            parent_barcode: parent.human_barcode,
            parent: nil,
            concentration: '0.8',
            volume: '10',
            number: 2
    end

    context 'when single' do
      let(:parent) { create :phi_x_stock_tube, tag_option: 'Single' }

      it 'returns Single' do
        expect(phi_x_spiked_buffer.tags).to eq('Single')
      end
    end

    context 'when dual' do
      let(:parent) { create :phi_x_stock_tube, tag_option: 'Dual' }

      it 'returns Dual' do
        expect(phi_x_spiked_buffer.tags).to eq('Dual')
      end
    end
  end
end
