# frozen_string_literal: true

# The descriptors and descriptor_fields columns get copied into the backup table
# unless they are nil. The down migration restores the columns
class BackupAssetDescriptableColumns < ActiveRecord::Migration[5.1]
  def up
    ActiveRecord::Base.transaction do
      ActiveRecord::Base.connection.execute(
        '
        INSERT INTO asset_descriptors_backup(asset_id, descriptor_fields, descriptors)
          SELECT id AS asset_id, descriptor_fields, descriptors
          FROM assets
          WHERE descriptors IS NOT NULL'
      )
    end
  end

  def down
    ActiveRecord::Base.connection.execute(
      '
      UPDATE assets a
      INNER JOIN asset_descriptors_backup adb ON (adb.asset_id = a.id)
      SET a.descriptor_fields = adb.descriptor_fields,
          a.descriptors = adb.descriptors
      WHERE adb.id IS NOT NULL
    '
    )
  end
end
