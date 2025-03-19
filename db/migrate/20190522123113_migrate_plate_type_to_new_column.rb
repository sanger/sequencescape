# frozen_string_literal: true

# Moves the plate type information contained in the descriptors column
# to  the new plate_type association
class MigratePlateTypeToNewColumn < ActiveRecord::Migration[5.1]
  # Migration specific version of Asset
  class MigratingAsset < ApplicationRecord
    self.table_name = 'assets'
    serialize :descriptors, coder: YAML

    def labware_type
      descriptors['Plate Type']
    end
  end

  # Pigration specific version of PlateType
  class LabwareType < ApplicationRecord
    self.table_name = 'plate_types'

    def self.id_for(name)
      @id_store ||=
        Hash.new { |store, lookup_name| store[lookup_name] = LabwareType.find_or_create_by!(name: lookup_name).id }
      @id_store[name]
    end
  end

  def up
    ActiveRecord::Base.transaction do
      MigratingAsset
        .where('descriptors like "%Plate Type%"')
        .find_each do |asset|
          labware_type_id = LabwareType.id_for(asset.labware_type)
          say "Updating #{asset.id} => #{asset.labware_type} (#{labware_type_id})"
          asset.update(labware_type_id:)
        end
    end
  end

  def down
    MigratingAsset.where('descriptors like "%Plate Type%"').update_all(labware_type_id: nil)
  end
end
