class AddMissingAssetLinksBetweenPlateAndTubes < ActiveRecord::Migration
  def up
    ActiveRecord::Base.transaction do |variable|
      Transfer::FromPlateToTubeBySubmission.find_each do |transfer|
        next if transfer.source.nil?
        transfer.destinations.each do |destination|
          next if destination.nil? || destination.parents.include?(transfer.source)
          AssetLink.create_edge!(transfer.source, destination)
        end
      end
      Transfer::FromPlateToTubeByMultiplex.find_each do |transfer|
        next if transfer.source.nil?
        transfer.destinations.each do |destination|
          next if destination.nil? || destination.parents.include?(transfer.source)
          AssetLink.create_edge!(transfer.source, destination)
        end
      end
      Transfer::BetweenTubesBySubmission.find_each do |transfer|
        next if transfer.source.nil?
        next if transfer.destination.nil? || transfer.destination.parents.include?(transfer.source)
        AssetLink.create_edge!(transfer.source, transfer.destination)
      end
    end

  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
