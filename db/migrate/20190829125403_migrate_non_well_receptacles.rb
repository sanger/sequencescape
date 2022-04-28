# frozen_string_literal: true

# All non well Receptacles are just Receptacles
class MigrateNonWellReceptacles < ActiveRecord::Migration[5.1]
  def up # rubocop:disable Metrics/AbcSize
    ActiveRecord::Base.connection.execute('SET autocommit = 0')
    ActiveRecord::Base.connection.execute('SET unique_checks = 0')
    ActiveRecord::Base.connection.execute('SET foreign_key_checks = 0')
    ActiveRecord::Base.connection.execute(
      "
      UPDATE receptacles
      SET receptacles.sti_type = 'Receptacle::Qc'
      WHERE receptacles.sti_type = 'QcTube'
    "
    )
    ActiveRecord::Base.connection.execute(
      "
      UPDATE receptacles
      SET receptacles.sti_type = 'Receptacle'
      WHERE receptacles.sti_type != 'Well'
        AND receptacles.sti_type != 'Receptacle::Qc'
        AND receptacles.sti_type != 'Lane'"
    )
    ActiveRecord::Base.connection.execute('COMMIT')
    ActiveRecord::Base.connection.execute('SET autocommit = 1')
    ActiveRecord::Base.connection.execute('SET unique_checks = 1')
    ActiveRecord::Base.connection.execute('SET foreign_key_checks = 1')
  end
end
