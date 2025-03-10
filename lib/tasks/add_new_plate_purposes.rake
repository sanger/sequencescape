# frozen_string_literal: true

# This Rake task adds new plate creators to the plate_creators table.
# It finds the existing plate purposes by their names and creates new
# plate creators with the specified purposes and valid options.
#
# Usage:
#   rake plate_creators:add_new_plate_purposes
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
    rna_plate_purpose = PlatePurpose.find_by!(name: 'scRNA Stock')

    # Creating the plate creators
    Plate::Creator.create!(
      name: 'Stock Plate',
      plate_purposes: [stock_plate_purpose],
      valid_options: {
        valid_dilution_factors: [1.0]
      }
    )
    Plate::Creator.create!(
      name: 'scRNA Stock Plate',
      plate_purposes: [rna_plate_purpose],
      valid_options: {
        valid_dilution_factors: [1.0]
      }
    )
    puts 'New plate purposes have been added to the plate_creators table.'
  end
end
