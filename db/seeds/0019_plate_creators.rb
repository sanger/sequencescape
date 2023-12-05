# frozen_string_literal: true

ActiveRecord::Base.transaction do
  excluded = ['Dilution Plates']

  # Build the links between the parent and child plate purposes
  relationships = {
    'Working Dilution' => ['Working Dilution', 'Pico Dilution'],
    'Pico Dilution' => ['Working Dilution', 'Pico Dilution'],
    'Pico Assay A' => ['Pico Assay A', 'Pico Assay B'],
    'Pulldown' => ['Pulldown Aliquot'],
    'Dilution Plates' => ['Working Dilution', 'Pico Dilution'],
    'Pico Assay Plates' => ['Pico Assay A', 'Pico Assay B'],
    'Pico Assay B' => ['Pico Assay A', 'Pico Assay B'],
    'Gel Dilution Plates' => ['Gel Dilution']
  }

  PlatePurpose
    .where(
      name: [
        'Stock Plate',
        'Normalisation',
        'Pico Standard',
        'Pulldown',
        'Dilution Plates',
        'Pico Assay Plates',
        'Gel Dilution Plates',
        'Aliquot 1',
        'Aliquot 2',
        'Aliquot 3',
        'Aliquot 4',
        'Aliquot 5'
      ]
    )
    .find_each do |plate_purpose|
      Plate::Creator
        .create!(name: plate_purpose.name)
        .tap do |creator|
          creator.plate_purposes = Purpose.where(name: relationships[plate_purpose.name] || plate_purpose.name)
        end unless excluded.include?(plate_purpose.name)
    end

  # Additional plate purposes required
  ['Pico dilution', 'Working dilution'].each do |name|
    plate_purpose = PlatePurpose.find_by!(name: name)
    Plate::Creator.create!(name: name, plate_purposes: [plate_purpose])
  end

  plate_purpose = PlatePurpose.find_by!(name: 'Pre-Extracted Plate')
  Plate::Creator.create!(
    name: 'Pre-Extracted Plate',
    plate_purposes: [plate_purpose],
    parent_plate_purposes: Purpose.where(name: 'Stock plate')
  )

  purposes_config = [
    [Plate::Creator.find_by!(name: 'Working dilution'), Purpose.find_by!(name: 'Stock plate')],
    [Plate::Creator.find_by!(name: 'Pico dilution'), Purpose.find_by!(name: 'Working dilution')],
    [Plate::Creator.find_by!(name: 'Pico Assay Plates'), Purpose.find_by!(name: 'Pico dilution')],
    [Plate::Creator.find_by!(name: 'Pico Assay Plates'), Purpose.find_by!(name: 'Working dilution')]
  ]

  purposes_config.each { |creator, purpose| creator.parent_plate_purposes << purpose }

  # Valid options: Dilution Factors:
  [['Working dilution', [12.5, 20.0, 15.0, 50.0]], ['Pico dilution', [4.0]]].each do |name, values|
    c = Plate::Creator.find_by!(name: name)
    c.update!(valid_options: { valid_dilution_factors: values })
  end
  Plate::Creator.find_each do |c|
    if c.valid_options.nil?
      # Any other valid option will be set to 1
      c.update!(valid_options: { valid_dilution_factors: [1.0] })
    end
  end

  # Add the 'Stock RNA Plate' purpose to the 'Working dilution' creator parent
  # purposes (if not added already) when db:seed is executed, for example
  # during db:reset .
  purpose = Purpose.find_by!(name: 'Stock RNA Plate')
  creator = Plate::Creator.find_by!(name: 'Working dilution')
  creator.parent_plate_purposes << purpose unless creator.parent_plate_purposes.include?(purpose)
end
