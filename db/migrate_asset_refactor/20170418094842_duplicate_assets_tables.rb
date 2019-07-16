# frozen_string_literal: true

# Duplicated the contents of the assets table into receptacles and labware
class DuplicateAssetsTables < ActiveRecord::Migration[4.2]
  def up
    say "LAST ASSET #{Asset.order(id: :desc).first&.id || 'NONE'}"
    ActiveRecord::Base.connection.execute('CREATE TABLE receptacles LIKE assets')
    ActiveRecord::Base.connection.execute('INSERT receptacles SELECT * FROM assets')
    ActiveRecord::Base.connection.execute('CREATE TABLE labware LIKE assets')
    ActiveRecord::Base.connection.execute('INSERT labware SELECT * FROM assets')
  end

  def down
    drop_table :receptacles
    drop_table :labware
  end
end
