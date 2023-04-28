# frozen_string_literal: true

COLUMN_RANGES = [(1..1), (1..2), (1..3), (1..4), (1..6), (1..12)].freeze

locations_96_wells = locations_for(('A'..'H'), (1..12))
locations_384_wells = locations_for(('A'..'P'), (1..24))

def locations_for(row_range, column_range)
  row_range.map { |row| column_range.map { |column| "#{row}#{column}" } }.flatten
end

def pooling_row_to_first_column_transfer_layout_96
  layout = {}
  ('A'..'H').each { |row| (1..12).each { |column| layout["#{row}#{column}"] = "#{row}1" } }
  layout
end

ActiveRecord::Base.transaction do
  # Plate-to-plate transfers
  COLUMN_RANGES.each do |range|
    TransferTemplate.create!(
      name: "Transfer columns #{range.first}-#{range.last}",
      transfer_class_name: Transfer::BetweenPlates.name,
      transfers: locations_for(('A'..'H'), range).to_h { |location| [location, location] }
    )
  end
  TransferTemplate.create!(
    name: 'Pool wells based on submission',
    transfer_class_name: Transfer::BetweenPlatesBySubmission.name
  )
  TransferTemplate.create!(name: 'Custom pooling', transfer_class_name: Transfer::BetweenPlates.name)

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
    transfers: locations_96_wells
  )

  TransferTemplate.create!(
    name: '384 plate to tube',
    transfer_class_name: 'Transfer::FromPlateToTube',
    transfers: locations_384_wells
  )

  TransferTemplate.create!(
    name: 'Flip Plate',
    transfer_class_name: 'Transfer::BetweenPlates',
    transfers: wells.zip(wells.reverse).to_h
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
