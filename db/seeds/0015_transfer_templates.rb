# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2011,2012,2013,2014,2015 Genome Research Ltd.

COLUMN_RANGES = [
  (1..1),
  (1..2),
  (1..3),
  (1..4),
  (1..6),
  (1..12)
]

def locations_for(row_range, column_range)
  row_range.map { |row| column_range.map { |column| "#{row}#{column}" } }.flatten
end

def pooling_row_to_first_column_transfer_layout_96
  layout = {}
  ('A'..'H').each do |row|
    (1..12).each do |column|
      layout["#{row}#{column}"] = "#{row}1"
    end
  end
  layout
end

ActiveRecord::Base.transaction do
  # Plate-to-plate transfers
  COLUMN_RANGES.each do |range|
    TransferTemplate.create!(
      name: "Transfer columns #{range.first}-#{range.last}",
      transfer_class_name: Transfer::BetweenPlates.name,
      transfers: Hash[locations_for(('A'..'H'), range).map { |location| [location, location] }]
    )
  end
  TransferTemplate.create!(
    name: 'Pool wells based on submission',
    transfer_class_name: Transfer::BetweenPlatesBySubmission.name
  )
  TransferTemplate.create!(
    name: 'Custom pooling',
    transfer_class_name: Transfer::BetweenPlates.name
  )

  # Plate-to-tube transfers
  TransferTemplate.create!(
    name: 'Transfer wells to MX library tubes by submission',
    transfer_class_name: Transfer::FromPlateToTubeBySubmission.name
  )
  TransferTemplate.create!(
    name: 'Transfer wells to specific tubes by submission',
    transfer_class_name: Transfer::FromPlateToSpecificTubes.name
  )

  # Tube-to-tube transfers
  TransferTemplate.create!(
    name: 'Transfer from tube to tube by submission',
    transfer_class_name: Transfer::BetweenTubesBySubmission.name
  )

  TransferTemplate.create!(
    name: 'Transfer wells to specific tubes defined by submission',
    transfer_class_name: 'Transfer::FromPlateToSpecificTubesByPool'
  )

  TransferTemplate.create!(
    name: 'Transfer between specific tubes',
    transfer_class_name: 'Transfer::BetweenSpecificTubes'
  )

  TransferTemplate.create!(
    name: 'Whole plate to tube',
    transfer_class_name: 'Transfer::FromPlateToTube',
    transfers: locations_for(('A'..'H'), (1..12))
  )

  wells = locations_for(('A'..'H'), (1..12))

  TransferTemplate.create!(
    name: 'Flip Plate',
    transfer_class_name: 'Transfer::BetweenPlates',
    transfers: Hash[wells.zip(wells.reverse)]
  )

  TransferTemplate.create!(
    name: 'Transfer wells to MX library tubes by multiplex',
    transfer_class_name: 'Transfer::FromPlateToTubeByMultiplex'
  )

  TransferTemplate.create!(
    name: 'Pooling rows to first column',
    transfer_class_name: 'Transfer::BetweenPlates',
    transfers: pooling_row_to_first_column_transfer_layout_96
  )
end
