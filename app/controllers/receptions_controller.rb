class ReceptionsController < ApplicationController
  before_filter :find_asset_by_id, :only => [:print, :snp_register]

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

    barcodes.each do |index,barcode|
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
      prefix, id, checksum = Barcode.split_barcode(barcode)

      case params[:type][:id]
      when 'LibraryTube' then @asset = LibraryTube.find_by_barcode(id)
      when 'MultiplexedLibraryTube' then @asset = MultiplexedLibraryTube.find_by_barcode(id)
      when 'PulldownMultiplexedLibraryTube' then @asset = PulldownMultiplexedLibraryTube.find_by_barcode(id)
      when 'Plate' then @asset = Asset.find_from_machine_barcode(barcode)
      when 'SampleTube' then @asset =  SampleTube.find_by_barcode(id)
      else
        @asset = Asset.find_from_machine_barcode(barcode)
      end


      if @asset.nil?
        @generic_asset = Asset.find_by_barcode(id)
        if @generic_asset.nil?
          @errors << "Sample with barcode #{barcode} not found"
        else
          @errors << "Incorrect type for #{barcode} is a #{@generic_asset.sti_type} not a #{params[:type][:id]}"
        end
        next
      else
        @assets << @asset
      end
    end

    if all_barcodes_blank
      @errors << "No barcodes have been entered or scanned!"
    end

    if @errors.size > 0
      respond_to do |format|
        flash[:error] = "Error with scanned samples"
        format.html { render :action => :index }
        format.xml  { render :xml  => @errors, :status => :unprocessable_entity }
        format.json { render :json => @errors, :status => :unprocessable_entity }
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
    location = Location.find(params[:asset][:location_id])
    assets = params[:asset_id]
    @errors = []
    asset_count  = 0

    assets.each do |index,asset_id|
      begin
        @asset = Asset.find(asset_id)
        @asset.update_attributes(params[:asset])
        asset_count += 1
        @asset.events.create_scanned_into_lab!(location)
      rescue
        @errors << "Sample not found with asset ID #{asset_id}"
      end
    end

    if @errors.size > 0
      respond_to do |format|
        flash[:error] = "Assets not found"
        format.html { render :action => "reception" }
        format.xml  { render :xml  => @errors, :status => :unprocessable_entity }
        format.json { render :json => @errors, :status => :unprocessable_entity }
      end
    else
      respond_to do |format|
        flash[:notice] = "Successfully updated #{asset_count} samples"
        format.html { render :action => "reception" }
        format.xml  { head :ok }
        format.json { head :ok }
      end
    end
  end

  def receive_snp_barcode
    barcodes = params[:barcodes]
    @snp_plates = []
    @errors = []

    barcodes.scan(/\d+/).each do |plate_barcode|
      plate = Plate.find_by_barcode(plate_barcode)
      if plate.nil?
        @snp_plates << plate_barcode
      else
        @snp_plates << plate
      end
    end

    if @errors.size > 0
      respond_to do |format|
        format.html { render :action => "snp_import" }
        format.xml  { render :xml  => @errors, :status => :unprocessable_entity }
        format.json { render :json => @errors, :status => :unprocessable_entity }
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
    respond_to do |format|
      if Plate.create_plates_with_barcodes(params)
        flash[:notice] = "Plates queued to be imported"
        format.html { redirect_to :action => "snp_import" }
        format.xml  { head :ok }
        format.json { head :ok }
      else
        flash[:errors] = "Plates could not be created"
        format.html { render :action => "snp_import" }
        format.xml  { render :xml  => @errors, :status => :unprocessable_entity }
        format.json { render :json => @errors, :status => :unprocessable_entity }
      end
    end
  end

  def find_asset_by_id
    @asset = Asset.find(params[:id])
  end

end
