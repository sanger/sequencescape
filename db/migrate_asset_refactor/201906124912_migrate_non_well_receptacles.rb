# frozen_string_literal: true

# All non well Receptacles are just Receptacles
class MigrateNonWellReceptacles < ActiveRecord::Migration[5.1]
  def up
    ActiveRecord::Base.connection.execute("
      UPDATE receptacles
      SET receptacles.sti_type = 'Receptacle'
      WHERE receptacles.sti_type != 'Well';
    ")
  end
end
