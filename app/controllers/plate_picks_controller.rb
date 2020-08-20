# Provides an interactive interface for quickly organizing plates into their
# associated picks.
class PlatePicksController < ApplicationController
  # Renders the plate_pick vue app
  def index
    render :index
  end

  def plates
    plate = Plate.find_by_barcode(params[:barcode])
    if plate.present?
      # Control plates are associated with a LOT of batches, and it doesn't really
      # make sense to load the entire list. We handle this in two ways:
      # 1. Don't waste time looking up the batches, and return an empty array
      # 2. Flag the plate as a control to allow us to apply appropriate styling.
      batches = if plate.pick_as_control?
                  []
                else
                  plate.batches_as_source.for_pipeline(CherrypickPipeline.all).ids.map(&:to_s)
                end

      render json: { plate: {
        id: plate.id,
        barcode: plate.machine_barcode,
        batches: batches,
        control: plate.pick_as_control?
      } }
    else
      render json: { errors: 'Could not find plate in Sequencescape' }, status: 404
    end
  end

  def batches
    batch = Batch.find(params[:id])
    # Either we're not a cherrypick batch, or we haven't been processed

    return render json: { errors: 'Batch has no pick information' }, status: 409 unless batch.pick_information?

    robot = batch.robot_id ? Robot.find(batch.robot_id) : Robot.with_verification_behaviour.first
    # Extract the plates in advance in a single query. This optimizes performance
    plate_information = batch.input_labware
                             .includes(:batches_as_source, :barcodes)
                             .where(batches: { pipeline_id: CherrypickPipeline.all })
                             .index_by(&:machine_barcode)
                             .transform_values do |plate|
                               {
                                 id: plate.id,
                                 barcode: plate.machine_barcode,
                                 batches: plate.batches_as_source.ids.map(&:to_s),
                                 control: plate.pick_as_control?
                               }
                             end
    picks = robot.all_picks(batch)

    if batch.present?
      render json: PlatePicks::BatchesJson.new(batch.id, picks, plate_information).to_json
    else
      render json: { errors: 'Could not find batch in Sequencescape' }, status: 404
    end
  end
end
