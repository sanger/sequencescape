class ReceptionsController < ApplicationController
  # WARNING! This filter bypasses security mechanisms in rails 4 and mimics rails 2 behviour.
  # It should be removed wherever possible and the correct Strong  Parameter options applied in its place.
  before_action :evil_parameter_hack!
  before_action :find_asset_by_id, only: [:print]

  def index
    @num_text_boxes = 10
  end

  def print
    @assets = [@asset]
  end

  def receive_barcode
    barcodes = params[:barcode]
    @new_plates = []
    @errors = []
    @assets = []

    all_barcodes_blank = true

    barcodes.each do |_index, barcode_ws|
      # We don't perform strip! as this results in modification of the parameters themselves, which affects logging and
      # exception notification. This can hinder investigation of any issues, as it changes apparent user input.
      barcode = barcode_ws.strip
      if barcode.blank?
        next
      else
        all_barcodes_blank = false
      end

      unless barcode.size == 13
        @errors << "Invalid barcode size for: #{barcode}"
        next
      end
      if Barcode.check_EAN(barcode) == false
        @errors << "Wrong barcode checksum for barcode: #{barcode}"
        next
      end

      asset = Asset.find_from_barcode(barcode)

      if asset.nil?
        @errors << "Asset with barcode #{barcode} not found"
      else
        @assets << asset
      end
    end

    if all_barcodes_blank
      @errors << 'No barcodes have been entered or scanned'
    end

    if @errors.size > 0
      respond_to do |format|
        flash[:error] = "Error with scanned samples: #{@errors.join('. ')}"
        format.html { render action: :index }
        format.xml  { render xml: @errors, status: :unprocessable_entity }
        format.json { render json: @errors, status: :unprocessable_entity }
      end
    else
      respond_to do |format|
        format.html
        format.xml  { head :ok }
        format.json { head :ok }
      end
    end
  end

  def confirm_reception
    ActiveRecord::Base.transaction do
      assets = params[:asset_id]
      @errors = []
      asset_count = 0

      assets.each do |_index, asset_id|
        asset = Asset.find_by(id: asset_id)
        if asset.nil?
          @errors << "Asset not found with asset ID #{asset_id}"
        else
          asset_count += 1
          asset.events.create_scanned_into_lab!('OLD RECEPTION', current_user.login)
          BroadcastEvent::LabwareReceived.create!(seed: asset, user: current_user, properties: { location_barcode: 'OLD RECEPTION' })
        end
      end

      if @errors.size > 0
        respond_to do |format|
          flash[:error] = "Could not update some locations: #{@errors.join(';')}"
          format.html { render action: 'reception' }
          format.xml  { render xml: @errors, status: :unprocessable_entity }
          format.json { render json: @errors, status: :unprocessable_entity }
        end
      else
        respond_to do |format|
          flash[:notice] = "Successfully updated #{asset_count} samples"
          format.html { render action: 'reception' }
          format.xml  { head :ok }
          format.json { head :ok }
        end
      end
    end
  end

  def find_asset_by_id
    @asset = Asset.find(params[:id])
  end
end
