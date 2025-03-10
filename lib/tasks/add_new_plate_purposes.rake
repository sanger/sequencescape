# frozen_string_literal: true

namespace :plate_creators do
  desc 'Add new plate purposes to the plate_creators table'
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
