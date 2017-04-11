# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2013,2014,2015 Genome Research Ltd.

module Tasks::PlateTransferHandler
  class InvalidBatch < StandardError; end

  def render_plate_transfer_task(task, _params)
    ActiveRecord::Base.transaction do
      @target = find_or_create_target(task)
    end
  end

  def includes_for_plate_creation
    [{ asset: [:map, { plate: [:plate_purpose, :barcode_prefix] }, :aliquots] }, { target_asset: [:pac_bio_library_tube_metadata] }]
  end

  def find_or_create_target(task)
    return target_plate if target_plate.present?
    # We only eager load the request stuff if we actually need it.
    batch_requests = @batch.requests.includes(includes_for_plate_creation)
    source_wells = batch_requests.map { |r| r.asset }
    raise InvalidBatch if unsuitable_wells?(source_wells)

    transfer_request_to_plate = RequestType.find_by(target_purpose_id: task.purpose_id) || RequestType.transfer
    transfer_request_from_plate = RequestType.transfer
    task.purpose.create!.tap do |target|
      well_map = Hash[target.wells.map { |well| [well.map_id, well] }]

      batch_requests.each do |outer_request|
        source = outer_request.asset
        transfer_request_to_plate.create!(
          asset: source,
          target_asset: well_map[source.map_id],
          submission_id: outer_request.submission_id
        )
        transfer_request_from_plate.create!(
          asset: well_map[source.map_id],
          target_asset: outer_request.target_asset,
          submission_id: outer_request.submission_id
        )
      end
    end
  end

  def target_plate
    transfer = TransferRequest.siblings_of(@batch.requests.first)
                              .for_submission_id(@batch.requests.first.submission_id)
                              .includes(target_asset: :plate).first
    return nil unless transfer.present?
    transfer.target_asset.plate
  end

  def unsuitable_wells?(source_wells)
    (source_wells - source_wells.first.plate.wells.with_contents).present?
  end
  private :unsuitable_wells?

  def do_plate_transfer_task(_task, _params)
    target_plate.transition_to('passed', current_user) unless target_plate.state == 'passed'
    true
  end
end
