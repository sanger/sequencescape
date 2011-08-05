class GenerateTransferTemplates < ActiveRecord::Migration
  COLUMN_RANGES = [
    (1..1),
    (1..2),
    (1..3),
    (1..4),
    (1..6),
    (1..12)
  ]

  def self.locations_for(row_range, column_range)
    row_range.map { |row| column_range.map { |column| "#{row}#{column}" } }.flatten
  end

  def self.up
    ActiveRecord::Base.transaction do
      # Plate-to-plate transfers
      COLUMN_RANGES.each do |range|
        TransferTemplate.create!(
          :name                => "Transfer columns #{range.first}-#{range.last}",
          :transfer_class_name => Transfer::BetweenPlates.name,
          :transfers           => Hash[locations_for(('A'..'H'), range).map { |location| [location, location] }]
        )
      end
      TransferTemplate.create!(
        :name                => "Pool wells based on submission",
        :transfer_class_name => Transfer::BetweenPlatesBySubmission.name
      )
      TransferTemplate.create!(
        :name                => "Custom pooling",
        :transfer_class_name => Transfer::BetweenPlates.name
      )

      # Plate-to-tube transfers
      TransferTemplate.create!(
        :name                => "Transfer wells to MX library tubes by submission",
        :transfer_class_name => Transfer::FromPlateToTubeBySubmission.name
      )
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      TransferTemplate.destroy_all
    end
  end
end
