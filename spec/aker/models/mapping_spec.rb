require 'rails_helper'

shared_examples 'a mapping between an Aker model and Sequencescape', aker: true do
  let(:config) {
    {
      # Maps SS models with Aker attributes
      map_ss_tables_with_aker: {
        samples: [],
        sample_metadata: [:gender, :donor_id, :phenotype, :common_name],
        well_attribute: [:volume, :concentration]
      },

      # Maps SS column names with Aker attributes (if the name is different)
      map_aker_with_ss_columns: {
        volume: :measured_volume,
        common_name: :sample_common_name
      },

      # Aker attributes allowed to update from Aker into SS
      updatable_attrs_from_aker_into_ss: [
        :gender, :donor_id, :phenotype, :common_name,
        :volume, :concentration
      ],

      # Aker attributes allowed to update from SS into Aker
      updatable_attrs_from_ss_into_aker: [:volume, :concentration]
    }    
  }
  context 'with a custom config' do
    before do
      Aker::Mapping.set_config(config)
    end

    context 'with private methods' do
      

      context '#table_for_attr' do
        it 'gives back a table name from an attribute name' do
          expect(mapping.send(:table_for_attr, :volume)).to eq(:well_attribute)
        end
        it 'returns nil if there is no table for the attribute' do
          expect(mapping.send(:table_for_attr, :volumes)).to eq(nil)
        end
      end

      context '#attributes_for_table' do
        it 'filters out the attributes that do not belong to the table' do
          expect(mapping.send(:attributes_for_table, :sample_metadata, {gender: 'Male', volume: 33})).to eq({gender: 'Male'})
        end
        it 'translates the valid attribute to the SS nomenclature using the config ' do
          expect(mapping.send(:attributes_for_table, :well_attribute, {gender: 'Male', volume: 33})).to eq({measured_volume: 33})
        end

      end

      context '#valid_attrs' do
        it 'filters out the attributes that do not have a valid key' do
          expect(mapping.send(:valid_attrs, [:gender], {gender: 'Male', volume: 33})).to eq({gender: 'Male'})
        end

        it 'translates the valid attribute to the SS nomenclature using the config ' do
          expect(mapping.send(:valid_attrs, [:volume], {gender: 'Male', volume: 33})).to eq({measured_volume: 33})
        end
      end

      context '#aker_attr_name' do
        it 'translates the valid attribute to the SS nomenclature using the config ' do
          expect(mapping.send(:aker_attr_name, :volume)).to eq(:measured_volume)
        end
      end

    end

  end
end

RSpec.describe Aker::Mapping, aker: true do
  let(:instance) { double('some model') }
  let(:mapping) { Aker::Mapping.new(instance) }

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
    end
    context '#update_attributes' do
      it 'updates an attribute translating to the right column of the model' do
        expect(some_model).to receive(:update_attributes).with(measured_volume: 44)
        mapping.update_attributes(volume: 44)
      end
    end    

  end
  
end