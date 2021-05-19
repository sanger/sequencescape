# frozen_string_literal: true

# All non well Receptacles are just Receptacles
class MigrateLaneLabware < ActiveRecord::Migration[5.1]
  def up
    ActiveRecord::Base.connection.execute(
      "
      UPDATE labware
      SET labware.sti_type = 'Lane::Labware'
      WHERE labware.sti_type = 'Lane';
    "
    )
  end
end
