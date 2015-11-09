#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2013,2015 Genome Research Ltd.
class IlluminaHtp::StockTubePurpose < Tube::Purpose
  def create_with_request_options(tube)
    raise 'Unimplemented behaviour'
  end

  def transition_to(tube, state, user, _ = nil, customer_accepts_responsibility = false)
    tube.requests_as_target.all(not_terminated).each do |request|
      request.transition_to(state)
    end
    outer_requests_for(tube).each do |request|
      request.customer_accepts_responsibility! if customer_accepts_responsibility
      request.transition_to(state)
    end if ['cancelled','failed','aborted'].include?(state)
  end

  def outer_requests_for(tube)
    tube.requests_as_target.map do |r|
      r.submission.requests.where_is_a(LibraryCompletion)
    end.uniq
  end

  def not_terminated
    {:conditions=>[ 'state NOT IN (?)',['cancelled','failed','aborted']]}
  end
  private :not_terminated

  def pool_id(tube)
    tube.requests_as_target.first.submission_id
  end

  def name_for_child_tube(tube)
    tube.name
  end

  def stock_plate(tube)
    return nil if tube.requests_as_target.empty?

    assets = [ tube.requests_as_target.first.asset ]
    until assets.empty?
      asset = assets.shift
      return asset.plate if asset.is_a?(Well) and asset.plate.stock_plate?
      assets.push(asset.requests_as_target.first.asset).compact
    end

    raise "Cannot locate stock plate for #{tube.display_name.inspect}"
  end

  def stock_wells(tube)
    tube.requests_as_target.map do |request|
      request.asset.stock_wells
    end.flatten
  end

end
