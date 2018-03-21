# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2011,2012,2015,2016 Genome Research Ltd.

unless Rails.env.test?
  ActiveRecord::Base.transaction do
    excluded = ['Dilution Plates']
    # Build the links between the parent and child plate purposes
    relationships = {
      'Working Dilution'    => ['Working Dilution', 'Pico Dilution'],
      'Pico Dilution'       => ['Working Dilution', 'Pico Dilution'],
      'Pico Assay A'        => ['Pico Assay A', 'Pico Assay B'],
      'Pulldown'            => ['Pulldown Aliquot'],
      'Dilution Plates'     => ['Working Dilution', 'Pico Dilution'],
      'Pico Assay Plates'   => ['Pico Assay A', 'Pico Assay B'],
      'Pico Assay B'        => ['Pico Assay A', 'Pico Assay B'],
      'Gel Dilution Plates' => ['Gel Dilution'],
      'Pulldown Aliquot'    => ['Sonication'],
      'Sonication'          => ['Run of Robot'],
      'Run of Robot'        => ['EnRichment 1'],
      'EnRichment 1'        => ['EnRichment 2'],
      'EnRichment 2'        => ['EnRichment 3'],
      'EnRichment 3'        => ['EnRichment 4'],
      'EnRichment 4'        => ['Sequence Capture'],
      'Sequence Capture'    => ['Pulldown PCR'],
      'Pulldown PCR'        => ['Pulldown qPCR']
    }

    PlatePurpose.where(name: [
      'Stock Plate', 'Normalisation', 'Pico Standard', 'Pulldown',
      'Dilution Plates', 'Pico Assay Plates', 'Gel Dilution Plates',
      'Aliquot 1', 'Aliquot 2', 'Aliquot 3', 'Aliquot 4', 'Aliquot 5'
    ]).find_each do |plate_purpose|
      Plate::Creator.create!(name: plate_purpose.name).tap do |creator|
        creator.plate_purposes = Purpose.where(name: relationships[plate_purpose.name] || plate_purpose.name)
      end unless excluded.include?(plate_purpose.name)
    end

    # Additional plate purposes required
    ['Pico dilution', 'Working dilution'].each do |name|
      plate_purpose = PlatePurpose.find_by!(name: name)
      Plate::Creator.create!(name: name, plate_purposes: [plate_purpose])
    end

    plate_purpose = PlatePurpose.find_by!(name: 'Pre-Extracted Plate')
    creator = Plate::Creator.create!(name: 'Pre-Extracted Plate', plate_purposes: [plate_purpose])
    creator.parent_plate_purposes << Purpose.find_by!(name: 'Stock plate')

    purposes_config = [
      [Plate::Creator.find_by!(name: 'Working dilution'), Purpose.find_by!(name: 'Stock plate')],
      [Plate::Creator.find_by!(name: 'Pico dilution'),     Purpose.find_by!(name: 'Working dilution')],
      [Plate::Creator.find_by!(name: 'Pico Assay Plates'), Purpose.find_by!(name: 'Pico dilution')],
      [Plate::Creator.find_by!(name: 'Pico Assay Plates'), Purpose.find_by!(name: 'Working dilution')],
    ]

    purposes_config.each do |creator, purpose|
      creator.parent_plate_purposes << purpose
    end

    # Valid options: Dilution Factors:
    [
      ['Working dilution', [12.5, 20.0, 15.0, 50.0]],
      ['Pico dilution', [4.0]]
    ].each do |name, values|
      c = Plate::Creator.find_by!(name: name)
      c.update_attributes!(valid_options: {
                             valid_dilution_factors: values
                           })
    end
    Plate::Creator.all.each do |c|
      if c.valid_options.nil?
        # Any other valid option will be set to 1
        c.update_attributes!(valid_options: {
                               valid_dilution_factors: [1.0]
                             })
      end
    end
  end
end
