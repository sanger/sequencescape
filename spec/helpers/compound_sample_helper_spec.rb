# frozen_string_literal: true

require 'spec_helper'
require './app/helpers/compound_sample_helper'

describe CompoundSampleHelper do
  describe '#find_or_create_compound_sample' do
    let(:study) { create(:study) }
    let!(:component_samples) { create_list(:sample, 3) }
    let!(:aliquots) { create_list(:aliquot, 2) }

    context 'when a compound sample does not exist' do
      before do
        helper.instance_variable_set(:@source_aliquots, aliquots)
      end

      it 'creates a new compound sample' do
        expect { helper.find_or_create_compound_sample(study, component_samples) }.to change(Sample, :count).by(1)
      end

      it 'configure the new compound sample correctly' do
        result = helper.find_or_create_compound_sample(study, component_samples)

        expect(result).to be_a(Sample)
        expect(result.component_samples).to eq(component_samples)
      end

      context 'when all source aliquots have the same supplier name' do
        before do
          aliquots.each do |aliquot|
            aliquot.sample.sample_metadata.update(supplier_name: 'Supplier A')
          end
        end

        it 'assigns the shared supplier name to the compound sample' do
          result = helper.find_or_create_compound_sample(study, component_samples)
          expect(result.supplier_name).to eq('Supplier A')
        end
      end

      context 'when source aliquots have different supplier names' do
        before do
          aliquots.each_with_index do |aliquot, index|
            aliquot.sample.sample_metadata.update(supplier_name: "Supplier #{index + 1}")
          end
        end

        it 'does not assign a supplier name to the compound sample' do
          result = helper.find_or_create_compound_sample(study, component_samples)
          expect(result.supplier_name).to be_nil
        end
      end
    end

    context 'when a compound sample already exists' do
      let!(:compound_sample) { create(:sample, component_samples:) }

      it 'does not create a new compound sample' do
        expect { helper.find_or_create_compound_sample(study, component_samples) }.not_to change(Sample, :count)
      end

      it 'returns the existing compound sample' do
        result = helper.find_or_create_compound_sample(study, component_samples)
        expect(result).to eq(compound_sample)
      end
    end
  end
end
