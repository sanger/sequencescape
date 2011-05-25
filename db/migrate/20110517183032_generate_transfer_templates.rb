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

      # Plate-to-tube transfers
      TransferTemplate.create!(
        :name                => "Transfer all wells to a tube",
        :transfer_class_name => Transfer::FromPlateToTube.name,
        :transfers           => locations_for(('A'..'H'), (1..12))
      )
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      TransferTemplate.destroy_all
    end
  end
end
