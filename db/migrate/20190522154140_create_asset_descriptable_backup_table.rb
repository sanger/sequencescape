# frozen_string_literal: true

# Here we create a temporary backup table to ensure we don't lose any data
# if we've missed something in the previous steps.
class CreateAssetDescriptableBackupTable < ActiveRecord::Migration[5.1]
  def change
    # We don't want timestamps it will only complicate things
    # rubocop:disable Rails/CreateTableWithTimestamps
    create_table :asset_descriptors_backup do |t|
      t.integer 'asset_id'
      t.text 'descriptor_fields'
      t.text 'descriptors'
    end
    # rubocop:enable Rails/CreateTableWithTimestamps
  end
end
