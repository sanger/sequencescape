# frozen_string_literal: true

# rubocop:disable RSpec/DescribeClass
require 'rails_helper'
require 'rake'

RSpec.describe 'retention_instructions:backfill' do

  before do
    Rake.application.rake_require "tasks/retention_instructions"
    Rake::Task.define_task(:environment)
  end

  context 'when retention instructions are there' do
    let(:run_rake_task) do
      Rake::Task['retention_instructions:backfill'].reenable
      Rake.application.invoke_task 'retention_instructions:backfill'
    end

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
  end

end

# rubocop:enable RSpec/DescribeClass