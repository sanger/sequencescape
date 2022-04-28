# frozen_string_literal: true

# The tasks are no longer used
class RemoveUnusedTasks < ActiveRecord::Migration[5.2]
  def up
    # We're removed the STI type  so lets destroy without instantiating
    Task.where(sti_type: %w[AssignTagsTask SetCharacterisationDescriptorsTask]).delete_all
  end

  def down
    raise ActiveRecord::IrreversibleMigration unless ENV['NO_REALLY'] == 'true'

    Workflow
      .find_by(name: 'Illumina-B MX Library Preparation')
      .tasks
      .create!(
        [
          { name: 'Assign Tags', sorted: 1, sti_type: 'AssignTagsTask', lab_activity: true },
          {
            name: 'Characterisation',
            sorted: 4,
            batched: true,
            sti_type: 'SetCharacterisationDescriptorsTask',
            lab_activity: true
          }
        ]
      )
    Workflow
      .find_by(name: 'Illumina-C MX Library Preparation')
      .tasks
      .create!(
        [
          { name: 'Assign Tags', sorted: 1, sti_type: 'AssignTagsTask', lab_activity: true },
          {
            name: 'Characterisation',
            sorted: 4,
            batched: true,
            interactive: false,
            per_item: false,
            sti_type: 'SetCharacterisationDescriptorsTask',
            lab_activity: true
          }
        ]
      )
    SetCharacterisationDescriptorsTask.each do |task|
      task.descriptors.create!(
        { name: 'Batch number of kit used', selection: { '1' => '' }, kind: 'Text', required: false, sorter: 1 },
        { name: 'Alternative reagents used', selection: { '1' => '' }, kind: 'Text', required: false, sorter: 2 },
        { name: 'Library storage box', selection: { '1' => '' }, kind: 'Text', required: false, sorter: 3 },
        { name: 'Library concentration', selection: { '1' => '' }, kind: 'Text', required: false, sorter: 4 },
        { name: 'Fragment size', selection: { '1' => '' }, kind: 'Text', required: false, sorter: 5 },
        { name: 'Protocol deviations', selection: { '1' => '' }, kind: 'Text', required: false, sorter: 6 },
        { name: 'Pooled library concentration', selection: { '1' => '' }, kind: 'Text', required: false, sorter: 6 },
        { name: 'Comments', selection: { '1' => '' }, kind: 'Text', required: false, sorter: 8 }
      )
    end
  end
end
