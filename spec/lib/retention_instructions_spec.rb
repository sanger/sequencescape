# spec/tasks/retention_instructions_rake_spec.rb

require 'rails_helper'
require 'rake'

RSpec.xdescribe 'retention_instructions:backfill' do
  before :all do
    Rake.application.rake_require "tasks/retention_instructions"
    Rake::Task.define_task(:environment)
  end

  describe 'backfill' do
    let(:run_rake_task) do
      Rake::Task['retention_instructions:backfill'].reenable
      Rake.application.invoke_task 'retention_instructions:backfill'
    end

    it 'will backfill retention instructions' do
      # Setup
      labware_with_metadata = create(:labware, retention_instruction: nil,
                                     custom_metadatum_collection:
                                       create(:custom_metadatum_collection,
                                              metadata: { 'retention_instruction' => 'some_value' }
                                       )
      )
      labware_without_metadata = create(:labware, retention_instruction: nil)

      # Execute
      run_rake_task

      # Verify
      expect(labware_with_metadata.reload.retention_instruction).not_to be_nil
      expect(labware_without_metadata.reload.retention_instruction).to be_nil
    end
  end
end