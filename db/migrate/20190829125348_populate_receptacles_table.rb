# frozen_string_literal: true

# Duplicated the contents of the assets table into receptacles and labware
class PopulateReceptaclesTable < ActiveRecord::Migration[4.2]
  def up
    ActiveRecord::Base.connection.execute('SET autocommit = 0')
    ActiveRecord::Base.connection.execute('SET unique_checks = 0')
    ActiveRecord::Base.connection.execute('SET foreign_key_checks = 0')

    ActiveRecord::Base.connection.execute(<<~SQLQUERY)
      INSERT receptacles (id, sti_type, qc_state, resource, map_id, closed,
             external_release, volume, concentration, labware_id,
             created_at, updated_at)
      SELECT assets.id AS id, assets.sti_type, assets.qc_state, assets.resource, assets.map_id, assets.closed,
             assets.external_release, assets.volume, assets.concentration,
             IF(assets.sti_type='Well',labware.id,assets.id) AS labware_id,
             IFNULL(assets.created_at, assets.updated_at) AS created_at, assets.updated_at
      FROM assets AS assets
      LEFT OUTER JOIN container_associations ca ON (ca.content_id = assets.id)
      LEFT OUTER JOIN labware ON (ca.container_id = labware.id)
      WHERE assets.sti_type NOT IN (
         "Plate", "PlateTemplate", "ControlPlate", "DilutionPlate", "PicoAssayPlate",
         "SequenomQcPlate", "StripTube", "WorkingDilutionPlate", "PicoDilutionPlate",
         "GelDilutionPlate"
       )
    SQLQUERY

    ActiveRecord::Base.connection.execute('COMMIT')
    ActiveRecord::Base.connection.execute('SET autocommit = 1')
    ActiveRecord::Base.connection.execute('SET unique_checks = 1')
    ActiveRecord::Base.connection.execute('SET foreign_key_checks = 1')
  end

  def down
    raise ActiveRecord::IrreversibleMigration if ENV['LAST_ASSET'].blank?

    Receptacle.where(['id < ?', ENV.fetch('LAST_ASSET', nil)]).delete_all
  end
end
