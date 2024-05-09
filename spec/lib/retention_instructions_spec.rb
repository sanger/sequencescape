# frozen_string_literal: true

# rubocop:disable RSpec/DescribeClass
require 'rails_helper'
require 'rake'

RSpec.describe 'retention_instructions:backfill' do

  shared_examples 'backfilling retention instructions' do

    it 'backfills retention instructions' do
      # Setup
      labware_with_metadata = create(:labware, retention_instruction: nil,
                                     custom_metadatum_collection:
                                       create(:custom_metadatum_collection,
                                              metadata: { 'retention_instruction' => 'Destroy after 2 years' }
                                       )
      )

      # Execute
      run_rake_task

      # Verify
      expect(labware_with_metadata.reload.retention_instruction).not_to be_nil
    end

    it 'removes from custom_metadata' do
      # Setup
      labware_with_metadata = create(:labware, retention_instruction: nil,
                                     custom_metadatum_collection:
                                       create(:custom_metadatum_collection,
                                              metadata: { 'retention_instruction' => 'Destroy after 2 years' }
                                       )
      )

      # Execute
      run_rake_task

      # Verify
      expect(labware_with_metadata.reload.custom_metadatum_collection.metadata['retention_instruction']).to be_nil
    end

    it 'removes only retention instructions from custom_metadata' do
      # Setup
      labware_with_metadata = create(:labware, retention_instruction: nil,
                                     custom_metadatum_collection:
                                       create(:custom_metadatum_collection,
                                              metadata: {
                                                'retention_instruction' => 'Destroy after 2 years',
                                                'other_key' => 'other_value'
                                              }
                                       )
      )

      # Execute
      run_rake_task

      # Verify
      expect(labware_with_metadata.reload.custom_metadatum_collection.metadata['other_key']).not_to be_nil
      expect(labware_with_metadata.reload.custom_metadatum_collection.metadata['other_key']).to eq('other_value')
    end

    it 'correctly backfills the data' do
      # Setup
      labware_with_metadata = create(:labware, retention_instruction: nil,
                                     custom_metadatum_collection:
                                       create(:custom_metadatum_collection,
                                              metadata: { 'retention_instruction' => 'Destroy after 2 years' }
                                       )
      )

      # Execute
      run_rake_task

      # Verify
      expect(labware_with_metadata.reload.retention_instruction.to_sym).to be(:destroy_after_2_years)
    end

    it 'correctly backfills the data (actual enum value)' do
      # Setup
      labware_with_metadata = create(:labware, retention_instruction: nil,
                                     custom_metadatum_collection:
                                       create(:custom_metadatum_collection,
                                              metadata: { 'retention_instruction' => 'Destroy after 2 years' }
                                       )
      )

      # Execute
      run_rake_task

      # Verify
      expect(labware_with_metadata.reload.retention_instruction_before_type_cast).to be(0)
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

  context 'when batch size is not given' do
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

end

# rubocop:enable RSpec/DescribeClass