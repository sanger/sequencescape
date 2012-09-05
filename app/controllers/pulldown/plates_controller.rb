class Pulldown::PlatesController < Pulldown::BaseController
  before_filter :login_required

  def index
    PulldownPlate.initialize_child_plates # force sub plate types to be initialised
    @pulldown_plates = PulldownPlate.find(:all, :limit => 20, :order => 'id DESC')
    @pulldown_aliquot_plates = PulldownAliquotPlate.paginate(:page => params[:page], :order => 'id DESC')
  end

  def new
    @plate = Plate.new
    @plate_purposes = PlatePurpose.find_all_by_pulldown_display(true)
    @barcode_printers = BarcodePrinter.find(:all, :order => "name asc")

    respond_to do |format|
      format.html
      format.xml  { render :xml  => @plate }
      format.json { render :json => @plate }
    end
  end

  def create
    ActiveRecord::Base.transaction do
      barcode_printer = BarcodePrinter.find(params[:plates][:barcode_printer])
      source_plate_barcodes = params[:plates][:source_plates]

      respond_to do |format|
        if Plate.create_default_plates_and_print_barcodes(source_plate_barcodes, barcode_printer, current_user)
          flash[:notice] = 'Created plates and printed barcodes'
          format.html { redirect_to('/pulldown/plates/new') }
          format.xml  { render :xml  => new_plates, :status => :created}
          format.json { render :json => new_plates, :status => :created}
        else
          flash[:error] = 'Failed to create plates'
          format.html { redirect_to('/pulldown/plates/new') }
          format.xml  { render :xml  => flash.to_xml, :status => :unprocessable_entity }
          format.json { render :json => flash.to_json, :status => :unprocessable_entity }
        end
      end
    end
  end

  def lookup_plate_purposes
    plate = Plate.plates_from_scanned_plate_barcodes(params[:plates][:source_plates]).first

    if plate && plate.plate_purpose && plate.plate_purpose.child_plate_purposes && plate.plate_purpose.child_plate_purposes.first
      render :text => "Creating '#{plate.plate_purpose.child_plate_purposes.first.name}' plates from '#{plate.plate_purpose.name}' plates", :layout => false
    else
      render :text => "", :layout => false
    end
  end

end
