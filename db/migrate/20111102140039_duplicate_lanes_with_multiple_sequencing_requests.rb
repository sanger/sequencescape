#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2011 Genome Research Ltd.
class DuplicateLanesWithMultipleSequencingRequests < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do
      Lane.find_each(:joins => :requests_as_target, :group => 'id', :having => 'COUNT(*) > 1') do |lane|
        original_request, *requests = lane.requests_as_target.all

        say_with_time("Duplicating for lane #{lane.id}, original request #{original_request.id}, duplicates #{requests.map(&:id).inspect}") do
          requests.each do |request|
            # Duplicate the lane
            duplicated_lane = request.target_asset.dup.tap do |duplicated_lane|
              duplicated_lane.aliquots = request.target_asset.aliquots.map(&:dup)
              duplicated_lane.save!

              duplicated_lane.comments.create!(
                :title       => 'De-duplicating lane that has multiple sequencing requests',
                :description => "This lane is a clone of #{original_request.target_asset.id}"
              )
              original_request.comments.create!(
                :title       => 'De-duplicating lane that has multiple sequencing requests',
                :description => "The lane #{duplicated_lane.id} is a clone of this one"
              )
            end

            # Update the request so that we can track the change
            request.update_attributes!(:target_asset => duplicated_lane)
            request.comments.create!(
              :title       => 'De-duplicating lane that has multiple sequencing requests',
              :description => "The target lane #{request.target_asset.id} is a clone of #{original_request.target_asset.id}"
            )
          end
        end
      end
    end
  end

  def self.down
    # Nothing to do here
  end
end
