# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2014,2015 Genome Research Ltd.

module Tasks::StripTubeCreationHandler
  def render_strip_tube_creation_task(task, _params)
    @tubes_requested = @batch.requests.first.asset.requests.for_pipeline(task.workflow.pipeline).count
    @tubes_available = @batch.requests.first.asset.requests.for_pipeline(task.workflow.pipeline).pending.count

    strip_count = task.descriptors.find_by!(key: 'strips_to_create')

    @options = strip_count.selection.select { |v| v <= (@tubes_available) }
    @default = strip_count.value || @options.last
  end

  def do_strip_tube_creation_task(task, params)
    tubes_to_create = params['tubes_to_create'].to_i

    locations_requests = @batch.requests.with_asset_location.pending.group_by { |r| r.asset.map.column_order }

    if locations_requests.any? { |_k, v| v.count < tubes_to_create }
      flash[:error] = 'There are insufficient requests remaining for the requested number of tubes.'
      flash[:error].concat(' Some wells of the plate have different numbers of requests.') if locations_requests.values.map(&:count).uniq.count > 1
      return false
    end

    if locations_requests.keys.sort != [0, 1, 2, 3, 4, 5, 6, 7]
      flash[:error] = 'This pipeline only supports wells in the first column.'
      return false
    end

    input_plate  = @batch.requests.first.asset.plate
    source_plate = input_plate.source_plate || input_plate

    if params['source_plate_barcode'] != input_plate.ean13_barcode
      flash[:error] = "'#{params['source_plate_barcode']}' is not the correct plate for this batch."
      return false
    end

    base_name = source_plate.sanger_human_barcode

    strip_purpose = Purpose.find_by(name: task.descriptors.find_by!(key: 'strip_tube_purpose').value)

    (0...tubes_to_create).each do |tube_number|
      tube = strip_purpose.create!(name: "#{base_name}:#{tube_number + 1}", location: @batch.pipeline.location)
      AssetLink::Job.create(source_plate, [tube])

      tube.size.times do |index|
        request = locations_requests[index].pop
        well    = tube.wells.in_column_major_order.all[index].id
        request.submission.next_requests(request).each do |dsr|
          dsr.update_attributes!(asset_id: well)
        end
        request.update_attributes!(target_asset_id: well)
      end
    end

    locations_requests.values.flatten.each do |request|
      @batch.remove_link(request)
      request.return_pending_to_inbox!
    end

    true
  end
end
