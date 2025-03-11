# frozen_string_literal: true

# This Rake task adds new plate creators to the plate_creators table.
# It finds the existing plate purposes by their names and creates new
# plate creators with the specified purposes and valid options.
#
# Usage:
#   [bundle exec] rake plate_creators:add_new_plate_purposes
#
# This task depends on the Rails environment being loaded, so it can
# access the models and database.
#
# Example:
#   To run this task, use the following command in your terminal:
#     [bundle exec] rake plate_creators:add_new_plate_purposes
#
# The task will output a message indicating that the new plate purposes
# have been added to the plate_creators table.
namespace :plate_creators do
  desc 'Add new plate creators to the plate_creators table'
  task add_new_plate_purposes: :environment do
    # Finding plate purposes
    stock_plate_purpose = PlatePurpose.find_by!(name: 'Stock Plate')
    rna_plate_purpose = PlatePurpose.find_by!(name: 'Stock RNA Plate')

    ActiveRecord::Base.transaction do
      # Creating the plate creators
      stock_plate_creator =
        Plate::Creator.find_or_create_by(name: 'Stock Plate') do |creator|
          creator.valid_options = { valid_dilution_factors: [1.0] }
        end
      rna_plate_creator =
        Plate::Creator.find_or_create_by!(name: 'scRNA Stock Plate') do |creator|
          creator.valid_options = { valid_dilution_factors: [1.0] }
        end

      # Create the relationships.
      Plate::Creator::PurposeRelationship.find_or_create_by!(
        plate_purpose_id: stock_plate_purpose.id,
        plate_creator_id: stock_plate_creator.id
      )

      Plate::Creator::PurposeRelationship.find_or_create_by!(
        plate_purpose_id: rna_plate_purpose.id,
        plate_creator_id: rna_plate_creator.id
      )

      puts 'New plate purposes have been added to the plate_creators table.'
    end
  end
end
