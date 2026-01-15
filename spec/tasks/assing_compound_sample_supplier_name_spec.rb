# frozen_string_literal: true
require 'rails_helper'

RSpec.describe 'compound_sample:set_consistent_supplier_name_for_compound_samples', type: :task do
  before do
    Rake.application.rake_require 'tasks/assign_compound_sample_supplier_name'
    Rake::Task.define_task(:environment)
  end

  let(:compound_sample_id) { 12 }
  let(:component_sample_id1) { 10 }
  let(:component_sample_id2) { 11 }

  let!(:samples) do
    [
      Sample.create!(id: compound_sample_id, name: 'compound_sample'),
      Sample.create!(id: component_sample_id1, name: 'component_sample_1'),
      Sample.create!(id: component_sample_id2, name: 'component_sample_2')
    ]
  end

  context 'when setting supplier names for previously created sample compounds' do
    before do
      SampleCompoundComponent.create!(compound_sample_id: compound_sample_id, component_sample_id: component_sample_id1)
      SampleCompoundComponent.create!(compound_sample_id: compound_sample_id, component_sample_id: component_sample_id2)
    end

    describe 'component samples with a consistent supplier_name' do
      before do
        Rake::Task['compound_sample:set_consistent_supplier_name_for_compound_samples'].reenable

        # Set component samples to the same supplier_name
        samples[0].sample_metadata.supplier_name = nil
        samples[1].sample_metadata.supplier_name = 'Supplier X'
        samples[2].sample_metadata.supplier_name = 'Supplier X'
        samples.each(&:save!)
      end

      it 'set compound sample to the same supplier name' do
        expect do
          Rake::Task['compound_sample:set_consistent_supplier_name_for_compound_samples'].invoke
        end.to change { samples[0].reload.sample_metadata.supplier_name }.from(nil).to('Supplier X')
      end
    end

    describe 'component samples with a a no consistent supplier_name' do
      before do
        Rake::Task['compound_sample:set_consistent_supplier_name_for_compound_samples'].reenable

        # Set component samples to different supplier names
        samples[0].sample_metadata.supplier_name = nil
        samples[1].sample_metadata.supplier_name = 'Supplier X'
        samples[2].sample_metadata.supplier_name = 'Supplier Y'
        samples.each(&:save!)
      end

      it 'keeps the component sample supplier name' do
        expect do
          Rake::Task['compound_sample:set_consistent_supplier_name_for_compound_samples'].invoke
        end.not_to(change { samples[0].reload.sample_metadata.supplier_name })
      end
    end

    describe 'compound sample already contains a supplier name' do
      before do
        Rake::Task['compound_sample:set_consistent_supplier_name_for_compound_samples'].reenable

        # Set component samples to different supplier names
        samples[0].sample_metadata.supplier_name = 'Supplier XY'
        samples[1].sample_metadata.supplier_name = 'Supplier X'
        samples[2].sample_metadata.supplier_name = 'Supplier X'
        samples.each(&:save!)
      end

      it 'keeps the component sample supplier name' do
        expect do
          Rake::Task['compound_sample:set_consistent_supplier_name_for_compound_samples'].invoke
        end.not_to(change { samples[0].reload.sample_metadata.supplier_name })
      end
    end
  end
end
