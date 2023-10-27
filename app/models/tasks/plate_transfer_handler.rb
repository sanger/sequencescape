# frozen_string_literal: true
module Tasks::PlateTransferHandler
  class InvalidBatch < StandardError
  end

  def render_plate_transfer_task(task, _params)
    ActiveRecord::Base.transaction { @target = find_or_create_target(task) }
  end

  def includes_for_plate_creation
    [{ asset: [:map, { plate: %i[plate_purpose barcodes] }, :aliquots] }, { target_asset: [] }]
  end

  # rubocop:todo Metrics/MethodLength
  def find_or_create_target(task) # rubocop:todo Metrics/AbcSize
    return target_plate if target_plate.present?

    # We only eager load the request stuff if we actually need it.
    batch_requests = @batch.requests.includes(includes_for_plate_creation)
    source_wells = batch_requests.map(&:asset)
    raise InvalidBatch if unsuitable_wells?(source_wells)

    task.purpose.create!.tap do |target|
      well_map = target.wells.index_by { |well| well.map_id }

      batch_requests.each do |outer_request|
        source = outer_request.asset
        TransferRequest.create!(
          asset: source,
          target_asset: well_map[source.map_id],
          submission_id: outer_request.submission_id
        )
        TransferRequest.create!(
          asset: well_map[source.map_id],
          target_asset: outer_request.target_asset,
          submission_id: outer_request.submission_id
        )
      end
    end
  end

  # rubocop:enable Metrics/MethodLength

  def target_plate
    transfer =
      TransferRequest
        .for_request(@batch.requests.first)
        .where(submission_id: @batch.requests.first.submission_id)
        .includes(target_asset: :plate)
        .first
    return nil if transfer.blank?

    transfer.target_asset.plate
  end

  def unsuitable_wells?(source_wells)
    # assumes all the source wells are on the same plate
    (source_wells - source_wells.first.plate.wells.with_contents).present?
  end
  private :unsuitable_wells?

  def do_plate_transfer_task(_task, _params)
    return if target_plate.state == 'passed'

    StateChange.create(target: target_plate, target_state: 'passed', user: current_user)
  end
end
