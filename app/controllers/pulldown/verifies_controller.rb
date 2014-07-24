class Pulldown::VerifiesController < Pulldown::BaseController
  before_filter :login_required

  def index
  end

  def validate_plates
    source_plate = Plate.plates_from_scanned_plate_barcodes(params[:plates][:source_plate]).first
    target_plate = Plate.plates_from_scanned_plate_barcodes(params[:plates][:target_plate]).first

    respond_to do |format|
      if target_plate && target_plate.parent == source_plate
        flash[:notice] = 'Success: plates match'
        format.html { redirect_to('/pulldown/verifies') }
        format.xml  { render :xml  => flash.to_xml,  :status => :ok}
        format.json { render :json => flash.to_json, :status => :ok}
      else
        flash[:error] = 'Error: plates do not match'
        format.html { redirect_to('/pulldown/verifies')  }
        format.xml  { render :xml  => flash.to_xml,  :status => :unprocessable_entity }
        format.json { render :json => flash.to_json, :status => :unprocessable_entity }
      end
    end
  end

  def source_plate_type
    plate = Plate.plates_from_scanned_plate_barcodes(params[:plates][:source_plate]).first

    if plate && plate.plate_purpose
      render :text => "#{plate.plate_purpose.name}", :layout => false
    else
      render :text => "", :layout => false
    end
  end

  def target_plate_type
    plate = Plate.plates_from_scanned_plate_barcodes(params[:plates][:target_plate]).first

    if plate && plate.plate_purpose
      render :text => "#{plate.plate_purpose.name}", :layout => false
    else
      render :text => "", :layout => false
    end
  end

end
