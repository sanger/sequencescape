class FailPulldownRequestsBasedOnFailedWellsOrPlates < ActiveRecord::Migration
  def self.library_requests_based_on(request)
    Request.where_is_a?(Pulldown::Requests::LibraryCreation).for_submission_id(request.submission_id).for_asset_id(request.asset.stock_wells.map(&:id))
  end

  def self.up
    ActiveRecord::Base.transaction do
      requests_to_fail = []

      # Find all of the wells that have been failed on any pulldown plate, and from them find the
      # pulldown library creation requests that should be failed because of this.
      PlatePurpose.find_each(:conditions => { :name => Pulldown::PlatePurposes::PULLDOWN_PLATE_PURPOSE_FLOWS.flatten }) do |purpose|
        say_with_time("Finding all requests for fail for #{purpose.name} plates") do
          Plate.find_in_batches(:conditions => { :plate_purpose_id => purpose.id }) do |batch|
            well_ids = batch.map(&:well_ids).flatten
            TransferRequest.failed.find_each(:conditions => { :target_asset_id => well_ids }) do |request|
              requests_to_fail.concat(library_requests_based_on(request))
            end
          end

          requests_to_fail.uniq!
          say "Now #{requests_to_fail.size} requests to fail"
        end
      end

      # Fail all of the library requests ...
      requests_to_fail.map(&:fail!)

      say "Failed: #{requests_to_fail.map(&:id).inspect}"
    end
  end

  def self.down
    # Nothing to do as the correct behaviour should be in place
  end
end
