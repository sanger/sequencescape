# Back populate asset links
class AddMissingAssetLinksBetweenPlateAndTubes < ActiveRecord::Migration
  def up
    Transfer::FromPlateToTubeBySubmission.find_each do |transfer|
      transfer.destinations.each do |destination|
        say "From Plate To Tube By Submission: #{transfer.source_id}-#{destination.id}"
        AssetLink.create_edge!(transfer.source, destination)
      end
    end
    Transfer::FromPlateToTubeByMultiplex.find_each do |transfer|
      transfer.destinations.each do |destination|
        say "From Plate To Tube By Multiplex: #{transfer.source_id}-#{destination.id}"
        AssetLink.create_edge!(transfer.source, destination)
      end
    end
    Transfer::BetweenTubesBySubmission.find_each do |transfer|
      say "Between Tubes By Submission: #{transfer.source_id}-#{transfer.destination.id}"
      AssetLink.create_edge!(transfer.source, transfer.destination)
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
