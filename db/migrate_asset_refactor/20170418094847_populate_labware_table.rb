# frozen_string_literal: true

# Duplicated the contents of the assets table into receptacles and labware
class PopulateLabwareTable < ActiveRecord::Migration[4.2]
  def up
    ActiveRecord::Base.connection.execute('SET autocommit = 0')
    ActiveRecord::Base.connection.execute('SET unique_checks = 0')
    ActiveRecord::Base.connection.execute('SET foreign_key_checks = 0')

    ActiveRecord::Base.connection.execute(<<~SQLQUERY
      INSERT labware (
             name, sti_type, size, public_name, two_dimensional_barcode,
             plate_purpose_id, labware_type_id, created_at, updated_at)
      SELECT name, sti_type, size, public_name, two_dimensional_barcode,
             plate_purpose_id, labware_type_id, created_at, updated_at
      FROM assets
      WHERE sti_type != "Well"
    SQLQUERY
                                         )

    ActiveRecord::Base.connection.execute('COMMIT')
    ActiveRecord::Base.connection.execute('SET autocommit = 1')
    ActiveRecord::Base.connection.execute('SET unique_checks = 1')
    ActiveRecord::Base.connection.execute('SET foreign_key_checks = 1')
    ActiveRecord::Base.connection.execute('ANALYZE TABLE labware')
  end

  def down
    raise ActiveRecord::IrreversibleMigration unless ENV['LAST_ASSET'].present

    Labware.where(['id < ?', ENV['LAST_ASSET']]).destroy_all
  end
end
