# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Cherrypick::Task::BufferVolumeForEmptyWellsOption, type: :module do
  # Had to include PickHelpers to access the valid_float_param? method, which is private in PickHelpers
  # but used in BufferVolumeForEmptyWellsOption.
  let(:dummy_class) do
    Class.new do
      include Cherrypick::Task::BufferVolumeForEmptyWellsOption
      include Cherrypick::Task::PickHelpers
    end
  end
  let(:instance) { dummy_class.new }
  let(:batch) { create(:batch) }

  before do
    instance.instance_variable_set(:@batch, batch)
    allow(instance).to receive(:valid_float_param?).and_return(true)
  end

  describe '#create_buffer_volume_for_empty_wells_option' do
    context 'when @batch is nil' do
      it 'returns nil' do
        instance.instance_variable_set(:@batch, nil)
        expect(instance.create_buffer_volume_for_empty_wells_option({})).to be_nil
      end
    end

    context 'when automatic_buffer_addition is not checked' do
      let(:params) { { automatic_buffer_addition: nil } }

      before do
        allow(batch).to receive(:set_poly_metadata)
      end

      it 'sets poly metadata' do
        instance.create_buffer_volume_for_empty_wells_option(params)
        expect(batch).to have_received(:set_poly_metadata).with(:automatic_buffer_addition, nil)
      end

      it 'returns nil' do
        result = instance.create_buffer_volume_for_empty_wells_option(params)
        expect(result).to be_nil
      end
    end

    context 'when automatic_buffer_addition is checked' do
      let(:params) { { automatic_buffer_addition: '1', buffer_volume_for_empty_wells: '10.0' } }

      before do
        allow(batch).to receive(:set_poly_metadata)
        allow(instance).to receive(:valid_float_param?).with('10.0').and_return(true)
      end

      it 'sets poly metadata for automatic_buffer_addition' do
        instance.create_buffer_volume_for_empty_wells_option(params)
        expect(batch).to have_received(:set_poly_metadata).with(:automatic_buffer_addition, '1')
      end

      it 'calls valid_float_param? with buffer volume' do
        instance.create_buffer_volume_for_empty_wells_option(params)
        expect(instance).to have_received(:valid_float_param?).with('10.0')
      end

      it 'sets poly metadata for buffer_volume_for_empty_wells' do
        instance.create_buffer_volume_for_empty_wells_option(params)
        expect(batch).to have_received(:set_poly_metadata).with(:buffer_volume_for_empty_wells, '10.0')
      end

      it 'raises error if buffer volume is invalid' do
        params = { automatic_buffer_addition: '1', buffer_volume_for_empty_wells: 'invalid' }
        allow(instance).to receive(:valid_float_param?).with('invalid').and_return(false)
        expect do
          instance.create_buffer_volume_for_empty_wells_option(params)
        end.to raise_error(Cherrypick::VolumeError, 'Invalid buffer volume for empty wells: invalid')
      end
    end

    context 'when automatic_buffer_addition is "on"' do
      let(:params) { { automatic_buffer_addition: 'on', buffer_volume_for_empty_wells: '5.5' } }

      before do
        allow(batch).to receive(:set_poly_metadata)
        allow(instance).to receive(:valid_float_param?).with('5.5').and_return(true)
      end

      it 'sets poly metadata for automatic_buffer_addition' do
        instance.create_buffer_volume_for_empty_wells_option(params)
        expect(batch).to have_received(:set_poly_metadata).with(:automatic_buffer_addition, 'on')
      end

      it 'calls valid_float_param? with buffer volume' do
        instance.create_buffer_volume_for_empty_wells_option(params)
        expect(instance).to have_received(:valid_float_param?).with('5.5')
      end

      it 'sets poly metadata for buffer_volume_for_empty_wells' do
        instance.create_buffer_volume_for_empty_wells_option(params)
        expect(batch).to have_received(:set_poly_metadata).with(:buffer_volume_for_empty_wells, '5.5')
      end
    end
  end
end
