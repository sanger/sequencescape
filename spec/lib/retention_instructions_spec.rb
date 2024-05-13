# frozen_string_literal: true

# rubocop:disable RSpec/DescribeClass
require 'rails_helper'
require 'rake'

RSpec.describe 'retention_instructions:backfill' do

  shared_examples 'backfilling retention instructions' do

    it 'backfills retention_instruction attribute in labware table' do
      labware = create(:custom_metadatum_collection,
                       metadata: { 'retention_instruction' => 'Destroy after 2 years' }
      ).asset

      # Execute
      run_rake_task

      # Verify
      expect(labware.reload.retention_instruction).not_to be_nil
      expect(labware.reload.retention_instruction.to_sym).to be(:destroy_after_2_years)
    end

    it 'removes existing retention instruction from custom_metadata table' do
      # Setup
      labware = create(:custom_metadatum_collection,
                       metadata: { 'retention_instruction' => 'Destroy after 2 years' }
      ).asset

      # Execute
      run_rake_task

      # Verify
      expect(labware.reload.custom_metadatum_collection.metadata['retention_instruction']).to be_nil
    end

    it 'removes only retention instructions from custom_metadata' do
      # Setup
      labware = create(:custom_metadatum_collection,
                       metadata: {
                         'retention_instruction' => 'Destroy after 2 years',
                         'other_key' => 'other_value'
                       }
      ).asset

      # Execute
      run_rake_task

      # Verify
      expect(labware.reload.custom_metadatum_collection.metadata['other_key']).to eq('other_value')
    end

    it 'correctly backfills the data (actual enum value)' do
      # Setup
      labware = create(:custom_metadatum_collection,
                       metadata: { 'retention_instruction' => 'Destroy after 2 years' }
      ).asset

      # Execute
      run_rake_task

      # Verify
      expect(labware.reload.retention_instruction_before_type_cast).to be(0)
    end
  end

  context 'when batch size is given' do
    let(:run_rake_task) do
      Rake::Task['retention_instructions:backfill'].reenable
      Rake.application.invoke_task 'retention_instructions:backfill[500]'
    end

    before do
      Rake.application.rake_require "tasks/retention_instructions"
      Rake::Task.define_task(:environment)
    end

    it_behaves_like 'backfilling retention instructions'
  end

  context 'when batch size is not given (i.e., the default batch size)' do
    let(:run_rake_task) do
      Rake::Task['retention_instructions:backfill'].reenable
      Rake.application.invoke_task 'retention_instructions:backfill'
    end

    before do
      Rake.application.rake_require "tasks/retention_instructions"
      Rake::Task.define_task(:environment)
    end

    it_behaves_like 'backfilling retention instructions'
  end

  context 'when an ActiveRecord error is thrown' do
    let(:run_rake_task) do
      Rake::Task['retention_instructions:backfill'].reenable
      Rake.application.invoke_task 'retention_instructions:backfill'
    end

    before do
      Rake.application.rake_require "tasks/retention_instructions"
      Rake::Task.define_task(:environment)
    end

    it 'rescues the ActiveRecord error and continues' do
      labware = create(:custom_metadatum_collection,
             metadata: { 'retention_instruction' => 'Destroy after 2 years' }
      ).asset

      allow(labware).to receive(:save!).and_raise(ActiveRecord::ActiveRecordError)
      allow(Labware.where(retention_instruction: nil)).to receive(:find_each).and_yield(labware)

      # Execute
      expect { run_rake_task }.not_to raise_error

      # Verify
      expect(labware.retention_instruction).to be_nil
    end
  end

  context 'when a large number or records are given',
          skip: 'Skipped as it slows down CI. Run it locally for testing purposes.' do
    let(:run_rake_task) do
      Rake::Task['retention_instructions:backfill'].reenable
      Rake.application.invoke_task 'retention_instructions:backfill'
    end

    before do
      Rake.application.rake_require "tasks/retention_instructions"
      Rake::Task.define_task(:environment)
    end

    it 'backfills retention instructions' do

      # Setup
      labwares = Array.new(2500) do
        create(:custom_metadatum_collection,
               metadata: { 'retention_instruction' => 'Destroy after 2 years' }
        ).asset
      end

      # Execute
      run_rake_task

      # Verify
      labwares.find_each do |labware|
        labware.reload
        expect(labware.retention_instruction).not_to be_nil
        expect(labware.custom_metadatum_collection.metadata['retention_instruction']).to be_nil
        expect(labware.custom_metadatum_collection).not_to be_nil
        expect(labware.retention_instruction.to_sym).to be(:destroy_after_2_years)
        expect(labware.retention_instruction_before_type_cast).to be(0)
      end

    end
  end

end

# rubocop:enable RSpec/DescribeClass