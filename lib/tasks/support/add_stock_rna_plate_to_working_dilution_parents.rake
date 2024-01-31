# frozen_string_literal: true

namespace :support do
  desc 'Add the Stock RNA Plate purpose to the parent purposes of the Working Dilution plate creator'
  task add_stock_rna_plate_to_working_dilution_parents: [:environment] do
    # This task allows the creation of 'Working Dilution' plates from 'Stock
    # RNA Plate' plates. It should only be run once per environment, if
    # necessary.The task adds the 'Stock RNA Plate' plate purpose to the parent
    # plate purposes of the 'Working dilution' plate creator. If the 'Stock RNA
    # Plate' plate purpose does not exist in the database, it is created first.
    # It is assumed that the 'Working dilution' plate creator exists and its
    # plate purposes contain the 'Working Dilution' purpose, but its parent
    # plate purposes do not contain the 'Stock RNA Plate' purpose. If the
    # purpose is already in the parent plate purposes, it is not added again.
    purpose_name = 'Stock RNA Plate'
    creator_name = 'Working dilution' # The second initial is lowercase in production.
    purpose = PlatePurpose.find_or_create_by!(name: purpose_name) { |p| p.stock_plate = true }
    creator = Plate::Creator.find_by!(name: creator_name)
    creator.parent_plate_purposes << purpose unless creator.parent_plate_purposes.include?(purpose)
  end
end
