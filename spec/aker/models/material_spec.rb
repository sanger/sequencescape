# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Aker::Material, type: :model, aker: true do
  let(:sample) { create :sample }
  let(:mapping) { Aker::Material.new(sample) }

  before do
    Aker::Material.config = my_config
  end

  it_behaves_like 'a mapping between an Aker model and Sequencescape'

  let(:my_config) do
    %Q{
    sample_metadata.gender              <=   gender
    sample_metadata.donor_id            <=   donor_id
    sample_metadata.phenotype           <=   phenotype
    sample_metadata.sample_common_name  <=   common_name
    well_attribute.measured_volume      <=>  volume      
    well_attribute.concentration        <=>  concentration
    }
  end
    # {
    #   # Maps SS models with Aker attributes
    #   map_ss_tables_with_aker: {
    #     samples: [],
    #     sample_metadata: [:gender, :donor_id, :phenotype, :common_name],
    #     well_attribute: [:volume, :concentration]
    #   },

    #   # Maps SS column names with Aker attributes (if the name is different)
    #   map_aker_with_ss_columns: {
    #     well_attribute: {
    #       volume: :measured_volume
    #     },
    #     sample_metadata: {
    #       common_name: :sample_common_name
    #     }
    #   },

    #   # Aker attributes allowed to update from Aker into SS
    #   updatable_attrs_from_aker_into_ss: [
    #     :gender, :donor_id, :phenotype, :common_name,
    #     :volume, :concentration
    #   ],

    #   # Aker attributes allowed to update from SS into Aker
    #   updatable_attrs_from_ss_into_aker: [:volume, :concentration]
  context 'with a custom config' do
    context '#attributes' do
      it 'generates an attributes object and adds the sample name as id' do
        container = double(:container)
        asset = double(:asset)
        well_attribute = double(:well_attribute, measured_volume: 14, concentration: 0.5)
        allow(sample).to receive(:container).and_return(container)
        allow(container).to receive(:asset).and_return(asset)
        allow(container).to receive(:a_well?).and_return(true)
        allow(asset).to receive(:well_attribute).and_return(well_attribute)

        expect(mapping.attributes).to eq(volume: 14, concentration: 0.5, '_id': sample.name)
      end

      context 'with any not defined attribute for sequencescape side' do
        let(:my_config) do
          %Q{
            bubidibu         =>  blublublu
          }
        end
        before do
          Aker::Mapping.config = my_config
        end

        it 'will try to get its value by calling the method in the material object' do
          mapping.instance_eval do
            def bubidibu
            end
          end
          allow(mapping).to receive(:bubidibu).and_return('a value')
          expect(mapping).to receive(:bubidibu)
          expect(mapping.attributes[:blublublu]).to eq('a value')
        end
      end

      context 'working with qc results' do
        let(:my_config) do
          %Q{
            concentration         =>  concentration
            volume                =>  volume
            amount                =>  amount
          }
        end
        let(:asset) { create :asset }
        let(:container) { create :container, asset: asset }

        before do
          Aker::Mapping.config = my_config
          allow(sample).to receive(:container).and_return(container)
          @conc_a = create :qc_result, key: 'Concentration', value: 33, asset: asset
          @conc_b = create :qc_result, key: 'Concentration', value: 44, asset: asset 

          @vol_a = create :qc_result, key: 'Volume', value: 0.33, asset: asset 
          @vol_b = create :qc_result, key: 'Volume', value: 0.44, asset: asset 
        end
        it 'returns the concentration from it' do
          expect(mapping.attributes[:concentration]).to eq(@conc_b.value)
        end
        it 'returns the volume from it' do
          expect(mapping.attributes[:volume]).to eq(@vol_b.value)
        end
        it 'returns the amount from it' do
          expect(mapping.attributes[:amount]).to eq((@conc_b.value.to_f * @vol_b.value.to_f).to_s)
        end
      end
    end
    context '#update' do
      before do
        sample.sample_metadata.update(gender: 'Male')
      end
      it 'updates an attribute' do
        expect(sample.sample_metadata.gender).to eq('Male')
        mapping.update(gender: 'Female')
        sample.sample_metadata.reload
        expect(sample.sample_metadata.gender).to eq('Female')
      end
    end
    # TODO
    # Private methods should not be tested, but through using public methods.
    # Maybe this method should be public.
    context 'with private methods' do
      context '#model_for_table' do
        it 'gives back a model object from a table name' do
          expect(mapping.send(:model_for_table, :sample_metadata)).to eq(sample.sample_metadata)
        end
        context 'when the asset is a plate' do
          let(:plate) { create :full_stock_plate }
          let(:well) { plate.wells.first }
          let(:container) { create :container, asset: well }
          before do
            allow(sample).to receive(:container).and_return(container)
          end
          it 'returns the model for the well_attribute' do
            expect(mapping.send(:model_for_table, :well_attribute)).to eq(well.well_attribute)
          end
        end
        context 'when the asset is a tube' do
          let(:tube) { create :tube }
          let(:container) { create :container, asset: tube }
          before do
            allow(sample).to receive(:container).and_return(container)
          end
          it 'returns the model for the well_attribute' do
            expect(mapping.send(:model_for_table, :well_attribute)).to eq(tube)
          end
        end
        it 'returns nil if there is no model object for the table name' do
          expect(mapping.send(:model_for_table, :bubidibu)).to eq(nil)
        end
      end
    end
  end
end
