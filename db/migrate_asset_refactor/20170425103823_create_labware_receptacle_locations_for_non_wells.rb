# frozen_string_literal: true

# Any receptacle which isn't a well, mostly {Tube tubes} has its self as its labware.
# This also covers lanes for the time-being (Although they should probably be
# grouped into flowcells) as well as a few weirder legacy things like {Fragment}
class CreateLabwareReceptacleLocationsForNonWells < ActiveRecord::Migration[4.2]
  def up
    ActiveRecord::Base.connection.execute("
      UPDATE receptacles
      SET receptacles.labware_id = receptacles.id
      WHERE receptacles.sti_type != 'Well';
    ")
  end
end
