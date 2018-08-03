# frozen_string_literal: true

require 'rails_helper'

shared_examples 'a mapping between an Aker model and Sequencescape', aker: true do
  context 'with a custom config' do
    before do
      Aker::Mapping.config = my_config
    end

    context 'with private methods' do
      context '#table_for_attr' do
        it 'gives back a table name from an attribute name' do
          expect(mapping.send(:tables_for_attr, :volume)).to eq([:well_attribute])
        end
        it 'returns :self if there is no table for the attribute' do
          expect(mapping.send(:tables_for_attr, :volumes)).to eq([:self])
        end
      end

      context '#attributes_for_table' do
        it 'filters out the attributes that do not belong to the table' do
          expect(mapping.send(:attributes_for_table, :sample_metadata, gender: 'Male', volume: 33)).to eq(gender: 'Male')
        end
        it 'translates the valid attribute to the SS nomenclature using the config ' do
          expect(mapping.send(:attributes_for_table, :well_attribute, gender: 'Male', volume: 33)).to eq(measured_volume: 33)
        end
      end

      context '#valid_attrs' do
        it 'filters out the attributes that do not have a valid key' do
          expect(mapping.send(:valid_attrs, :sample_metadata, [:gender], gender: 'Male', volume: 33)).to eq(gender: 'Male')
        end

        it 'translates the valid attribute to the SS nomenclature using the config ' do
          expect(mapping.send(:valid_attrs, :well_attribute, [:volume], gender: 'Male', volume: 33)).to eq(measured_volume: 33)
        end
      end

      context '#aker_attr_name' do
        it 'translates the valid attribute to the SS nomenclature using the config ' do
          expect(mapping.send(:aker_attr_name, :well_attribute, :volume)).to eq(:measured_volume)
        end
        it 'returns the passed attr name when no translation is defined for the attribute ' do
          expect(mapping.send(:aker_attr_name, :well_attribute, :volume2)).to eq(:volume2)
        end
        it 'returns the passed attr name when no model translation is defined' do
          expect(mapping.send(:aker_attr_name, :unknown_model, :unknown_attribute)).to eq(:unknown_attribute)
        end
      end
    end
  end
end

RSpec.describe Aker::Mapping, aker: true do
  let(:instance) { double('some model') }
  let(:mapping) { Aker::Mapping.new(instance) }
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
    Aker::Mapping.config = my_config
  end

  it_behaves_like 'a mapping between an Aker model and Sequencescape'

  context 'with a custom definition for #model_for_table' do
    let(:some_model) { double('model', measured_volume: 33, concentration: 0.3) }

    before do
      allow(mapping).to receive(:model_for_table).and_return(some_model)
    end

    context '#attributes' do
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
          Aker::Mapping.config = my_config
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
    context '#update' do
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
          Aker::Mapping.config = my_config
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
    context '#update!' do
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
