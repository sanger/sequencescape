#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2014 Genome Research Ltd.
# In contrast to pooling by submission, this method looks at submissions off the current
# plate. This allows users to use QC feedback to decide how to multiplex their plate.
class Transfer::FromPlateToTubeByMultiplex < Transfer::BetweenPlateAndTubes

  def locate_mx_library_tube_for(well)
    well.requests_as_source.where_is_a?(Request::Multiplexing).detect{|r| r.target_asset.aliquots.empty? }.try(:target_asset)
  end
  private :locate_mx_library_tube_for

  def well_to_destination
    @w2d||=ActiveSupport::OrderedHash[
      source.wells.map do |well|
        tube = locate_mx_library_tube_for(well)
        (tube.nil? or should_well_not_be_transferred?(well)) ? nil : [ well, [ tube, tube.requests_as_target.map(&:asset) ] ]
      end.compact
    ]
  end
  private :well_to_destination


  # Before creating an instance of this class the appropriate transfers need to be made from a source
  # asset to the destination one.
  # before_create :create_transfer_requests
  def create_transfer_requests
    each_transfer do |source, destination|
      request_type_between(source, destination).create!(
        :asset         => source,
        :target_asset  => destination,
        :submission_id => destination.requests_as_target.first.submission_id
      )
    end
  end
  private :create_transfer_requests

end
