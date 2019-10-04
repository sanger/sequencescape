# frozen_string_literal: true

require 'rails_helper'
require_relative '../shared/a_mapping_between_an_aker_model_and_sequencescape'

RSpec.describe Aker::Material, type: :model, aker: true do
  let(:sample) { create :sample, name: 'test1' }
  let(:mapping) { described_class.new(sample) }

  before do
    described_class.config = my_config
  end

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

  it_behaves_like 'a mapping between an Aker model and Sequencescape'

  context 'with a custom config' do
    describe '#attributes' do
      it 'generates an attributes object and adds the sample uuid as id' do
        container = double(:container)
        asset = double(:asset)
        well_attribute = double(:well_attribute, measured_volume: 14, concentration: 0.5)
        allow(sample).to receive(:container).and_return(container)
        allow(container).to receive(:asset).and_return(asset)
        allow(container).to receive(:a_well?).and_return(true)
        allow(asset).to receive(:well_attribute).and_return(well_attribute)

        expect(mapping.attributes).to eq(volume: 14, concentration: 0.5, '_id': sample.uuid)
      end

      context 'working with qc results' do
        let(:my_config) do
          %(
            concentration         =>  concentration
            volume                =>  volume
            amount                =>  amount
          )
        end
        let(:asset) { create :receptacle }
        let(:container) { create :container, asset: asset }

        before do
          described_class.config = my_config
          allow(sample).to receive(:container).and_return(container)
          @conc_a = create :qc_result_concentration, value: 33, asset: asset
          @conc_b = create :qc_result_concentration, value: 44, asset: asset

          @vol_a = create :qc_result_volume, value: 0.33, asset: asset
          @vol_b = create :qc_result_volume, value: 0.44, asset: asset
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

    describe '#update' do
      before do
        sample.sample_metadata.update(gender: 'Male')
      end

      it 'updates an attribute' do
        expect(sample.sample_metadata.gender).to eq('Male')
        mapping.update(gender: 'Female')
        sample.sample_metadata.reload
        expect(sample.sample_metadata.gender).to eq('Female')
      end

      context 'when the same value goes to two different models' do
        before do
          described_class.config =
            %(
                sample.name                         <=   supplier_name
                sample_metadata.sample_public_name  <=   supplier_name
                sample_metadata.sample_taxon_id     <=   taxon_id
                sample_metadata.gender              <=   gender
                sample_metadata.donor_id            <=   donor_id
                sample_metadata.phenotype           <=   phenotype
                sample_metadata.sample_common_name  <=   common_name
                volume                               =>  volume
                concentration                        =>  concentration
                amount                               =>  amount
              )
        end

        it 'updates both values' do
          mapping.update(supplier_name: 'test1')
          expect(sample.name).to eq('test1')
          sample.sample_metadata.reload
          expect(sample.sample_metadata.sample_public_name).to eq('test1')
        end
      end
    end
    # TODO
    # Private methods should not be tested, but through using public methods.
    # Maybe this method should be public.

    context 'with private methods' do
      describe '#model_for_table' do
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
            expect(mapping.send(:model_for_table, :well_attribute)).to eq(tube.receptacle)
          end
        end

        it 'returns nil if there is no model object for the table name' do
          expect(mapping.send(:model_for_table, :bubidibu)).to eq(nil)
        end
      end
    end
  end
end
