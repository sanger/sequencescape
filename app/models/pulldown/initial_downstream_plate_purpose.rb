#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2013 Genome Research Ltd.
class Pulldown::InitialDownstreamPlatePurpose < IlluminaHtp::InitialDownstreamPlatePurpose
  # Initial plates in the pulldown pipelines change the state of the pulldown requests they are being
  # created for to exactly the same state.

  def stock_wells(plate,contents)
    return plate.parents.map {|parent| parent.wells}.flatten unless contents.present?
    Well.find(:all, :joins => :requests, :conditions => {:requests => {:target_asset_id => plate.wells.located_at(contents).map(&:id)}})
  end

  def supports_multiple_submissions?; true; end

end
