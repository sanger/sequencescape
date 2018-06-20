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
    {
      # Maps SS models with Aker attributes
      map_ss_tables_with_aker: {
        samples: [],
        sample_metadata: [:gender, :donor_id, :phenotype, :common_name],
        well_attribute: [:volume, :concentration]
      },

      # Maps SS column names with Aker attributes (if the name is different)
      map_aker_with_ss_columns: {
        well_attribute: {
          volume: :measured_volume
        },
        sample_metadata: {
          common_name: :sample_common_name
        }
      },

      # Aker attributes allowed to update from Aker into SS
      updatable_attrs_from_aker_into_ss: [
        :gender, :donor_id, :phenotype, :common_name,
        :volume, :concentration
      ],

      # Aker attributes allowed to update from SS into Aker
      updatable_attrs_from_ss_into_aker: [:volume, :concentration]
    }
  end
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
