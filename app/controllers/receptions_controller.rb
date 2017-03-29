# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2014,2015 Genome Research Ltd.

class ReceptionsController < ApplicationController
  # WARNING! This filter bypasses security mechanisms in rails 4 and mimics rails 2 behviour.
  # It should be removed wherever possible and the correct Strong  Parameter options applied in its place.
  before_action :evil_parameter_hack!
  before_action :find_asset_by_id, only: [:print, :snp_register]

  def index
    @num_text_boxes = 10
  end

  def snp_import
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

      asset = Asset.find_from_machine_barcode(barcode)

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
      location = Location.find(params[:location_id])
      assets = params[:asset_id]
      @errors = []
      asset_count = 0

      assets.each do |_index, asset_id|
        asset = Asset.find_by(id: asset_id)
        if asset.nil?
          @errors << "Asset not found with asset ID #{asset_id}"
        else
          asset.update_attributes(location: location)
          asset_count += 1
          asset.events.create_scanned_into_lab!(location)
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

  def receive_snp_barcode
    barcodes = params[:barcodes]
    @snp_plates = []
    @errors = []

    barcodes.scan(/\d+/).each do |plate_barcode|
      plate = Plate.find_by(barcode: plate_barcode)
      if plate.nil?
        @snp_plates << plate_barcode
      else
        @snp_plates << plate
      end
    end

    if @errors.size > 0
      respond_to do |format|
        format.html { render action: 'snp_import' }
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

  def import_from_snp
    ActiveRecord::Base.transaction do
      respond_to do |format|
        if Plate.create_plates_with_barcodes(params)
          flash[:notice] = 'Plates queued to be imported'
          format.html { redirect_to action: 'snp_import' }
          format.xml  { head :ok }
          format.json { head :ok }
        else
          flash[:errors] = 'Plates could not be created'
          format.html { render action: 'snp_import' }
          format.xml  { render xml: @errors, status: :unprocessable_entity }
          format.json { render json: @errors, status: :unprocessable_entity }
        end
      end
    end
  end

  def find_asset_by_id
    @asset = Asset.find(params[:id])
  end
end
