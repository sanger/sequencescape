# frozen_string_literal: true

# This migration adds the 'Stock RNA Plate' plate purpose to the parent plate
# purposes of the 'Working dilution' plate creator.
#
# If the 'Stock RNA Plate' plate purpose does not exist in the database, it is
# created first.
#
# It is assumed that the 'Working dilution' plate creator exists and its plate
# purposes contain 'Working Dilution' purpose but its parent plate purposes
# does not contain the 'Stock RNA Plate' purpose.
#
# If the migration is rolled back, the 'Stock RNA Plate' purpose is removed from
# the parent plate purposes of the 'Working dilution' plate creator. However,
# the 'Stock RNA Plate' plate purpose is kept in the database.
#
class AddStockRnaPlateToWorkingDilutionParentPurposes < ActiveRecord::Migration[6.0]
  PURPOSE_NAME = 'Stock RNA Plate'
  CREATOR_NAME = 'Working dilution'

  def up
    purpose = PlatePurpose.find_or_create_by!(name: PURPOSE_NAME) { |p| p.stock_plate = true }
    creator = Plate::Creator.find_by!(name: CREATOR_NAME)
    creator.parent_plate_purposes << purpose
  end

  def down
    purpose = PlatePurpose.find_by!(name: PURPOSE_NAME)
    creator = Plate::Creator.find_by!(name: CREATOR_NAME)
    creator.parent_plate_purposes.delete(purpose)
  end
end
