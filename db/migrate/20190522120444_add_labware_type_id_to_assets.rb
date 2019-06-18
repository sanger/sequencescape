# frozen_string_literal: true

# {PlateType} in contrast to {PlatePurpose} represents the physical form-factor
# of the plate. It was previously stored as a string in a serialized hash
# called 'Descriptors' but has been migrated to an association for performance
# and maintenance reasons.
# We use the term labware_type rather than plate_type in anticipation of
# future migrations
# Note: Rails 4.2 to keep column types correct for foreign key
class AddLabwareTypeIdToAssets < ActiveRecord::Migration[4.2]
  def change
    add_reference :assets, :labware_type
    add_foreign_key :assets, :plate_types, column: :labware_type_id
  end
end
