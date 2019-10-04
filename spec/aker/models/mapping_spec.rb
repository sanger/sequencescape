# frozen_string_literal: true

require 'rails_helper'
require_relative '../shared/a_mapping_between_an_aker_model_and_sequencescape'

RSpec.describe Aker::Mapping, aker: true do
  let(:instance) { double('some model') }
  let(:mapping) { described_class.new }
  let(:my_config) do
    %(
    sample_metadata.gender              <=   gender
    sample_metadata.donor_id            <=   donor_id
    sample_metadata.phenotype           <=   phenotype
    sample_metadata.sample_common_name  <=   common_name
    well_attribute.measured_volume      <=>  volume
    well_attribute.concentration        <=>  concentration
    )
  end

  before do
    described_class.config = my_config
  end

  it_behaves_like 'a mapping between an Aker model and Sequencescape'

  context 'with a custom definition for #model_for_table' do
    let(:some_model) { double('model', measured_volume: 33, concentration: 0.3) }

    before do
      allow(mapping).to receive(:model_for_table).and_return(some_model)
    end

    describe '#attributes' do
      it 'generates an attributes object using the config definition and translating' do
        expect(mapping.attributes).to eq(volume: 33, concentration: 0.3)
      end

      context 'with any not defined attribute for sequencescape side' do
        let(:my_config) do
          %(
            bubidibu         =>  blublublu
          )
        end

        before do
          allow(mapping).to receive(:model_for_table).and_return(nil)
          described_class.config = my_config
        end

        it 'will try to get its value by calling the get method in the mapping object' do
          mapping.instance_eval do
            def bubidibu; end
          end
          allow(mapping).to receive(:bubidibu).and_return('a value')
          expect(mapping).to receive(:bubidibu)
          expect(mapping.attributes[:blublublu]).to eq('a value')
        end
      end
    end

    describe '#update' do
      it 'updates an attribute translating to the right column of the model' do
        allow(some_model).to receive(:update).with(measured_volume: 44).and_return(true)
        allow(some_model).to receive(:update).with(gender: 'Male').and_return(true)
        expect(mapping.update(volume: 44, gender: 'Male')).to eq(true)
      end

      it 'returns false when it cannot update one of the attrs' do
        allow(some_model).to receive(:update).with(gender: 'Male').and_return(true)
        allow(some_model).to receive(:update).with(measured_volume: 44).and_return(false)
        expect(mapping.update(volume: 44, gender: 'Male')).to eq(false)
      end

      context 'with any not defined attribute for sequencescape side' do
        let(:my_config) do
          %(
            bubidibu        <=  blublublu
          )
        end

        before do
          allow(mapping).to receive(:model_for_table).and_return(nil)
          described_class.config = my_config
        end

        it 'will try to update its value by calling the set method in the material object' do
          mapping.instance_eval do
            def bubidibu=(value); end
          end
          expect(mapping).to receive(:bubidibu=).with('some value')
          mapping.update(blublublu: 'some value')
        end
      end
    end

    describe '#update!' do
      it 'updates an attribute translating to the right column of the model' do
        allow(some_model).to receive(:update).with(measured_volume: 44).and_return(true)
        expect { mapping.update!(volume: 44) }.not_to raise_error
      end

      it 'raises error when it cannot update one of the attrs' do
        allow(some_model).to receive(:update).with(gender: 'Male').and_return(true)
        allow(some_model).to receive(:update).with(measured_volume: 44).and_raise('boom!')
        expect { mapping.update!(volume: 44, gender: 'Male') }.to raise_error('boom!')
      end
    end
  end
end
