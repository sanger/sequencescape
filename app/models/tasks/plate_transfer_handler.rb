#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2013,2014 Genome Research Ltd.
module Tasks::PlateTransferHandler

  class InvalidBatch < StandardError; end

  def render_plate_transfer_task(task,params)
    ActiveRecord::Base.transaction do
      @target = find_or_create_target(task)
    end
  end

  def find_or_create_target(task)
    return target_plate if target_plate.present?
    source_wells = @batch.requests.map {|r| r.asset}
    raise InvalidBatch if unsuitable_wells?(source_wells)
    task.purpose.create!.tap do |target|
      @batch.requests.each do |outer_request|
        source = outer_request.asset
        (RequestType.find_by_target_purpose_id(task.purpose_id)||RequestType.transfer).create!(
          :asset => source,
          :target_asset => target.wells.located_at(source.map_description).first,
          :submission_id => outer_request.submission_id
        )
        RequestType.transfer.create!(
          :asset => target.wells.located_at(source.map_description).first,
          :target_asset => outer_request.target_asset,
          :submission_id => outer_request.submission_id
        )
      end
    end
  end

  def target_plate
    transfer = @batch.requests.first.asset.requests.where_is_a?(TransferRequest).find_by_submission_id(@batch.requests.first.submission_id)
    return nil unless transfer.present?
    transfer.target_asset.plate
  end

  def unsuitable_wells?(source_wells)
    (source_wells - source_wells.first.plate.wells.with_contents).present?
  end
  private :unsuitable_wells?

  def do_plate_transfer_task(task,params)
    target_plate.transition_to('passed')
    true
  end

end
