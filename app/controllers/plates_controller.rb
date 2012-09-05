class PlatesController < ApplicationController
  before_filter :login_required, :except => [:upload_pico_results]

  def new
    @plate_creators   = Plate::Creator.all(:order => 'name ASC')
    @barcode_printers = BarcodePrinterType.find_by_name("96 Well Plate").barcode_printers
    @barcode_printers = BarcodePrinter.find(:all, :order => "name asc") if @barcode_printers.blank?

    respond_to do |format|
      format.html
      format.xml  { render :xml  => @plate }
      format.json { render :json => @plate }
    end
  end

  def show
    @plate = Plate.find(params[:id])
  end

  def create
    ActiveRecord::Base.transaction do
      plate_creator         = Plate::Creator.find(params[:plates][:creator_id])
      barcode_printer       = BarcodePrinter.find(params[:plates][:barcode_printer])
      source_plate_barcodes = params[:plates][:source_plates]

      user_barcode = Barcode.barcode_to_human(params[:plates][:user_barcode])
      scanned_user = User.find_by_barcode(user_barcode) if user_barcode

      respond_to do |format|
        if scanned_user.nil?
          flash[:error] = 'Please scan your user barcode'
          format.html { redirect_to(new_plate_path) }
        elsif plate_creator.execute(source_plate_barcodes, barcode_printer, scanned_user)
          flash[:notice] = 'Created plates and printed barcodes'
          format.html { redirect_to(new_plate_path) }
        else
          flash[:error] = 'Failed to create plates'
          format.html { redirect_to(new_plate_path) }
        end
      end
    end
  end

  def to_sample_tubes
    @locations = Location.all
    @barcode_printers = BarcodePrinter.all
    @studies = Study.all.sort{ |a,b| a.name <=> b.name }
  end

  def create_sample_tubes
    location = Location.find(params[:plates][:destination_freezer])
    barcode_printer = BarcodePrinter.find(params[:plates][:barcode_printer])
    plates = Plate.plates_from_scanned_plates_and_typed_plate_ids(params[:plates][:source_plates])
    study = Study.find(params[:plates][:study])

    respond_to do |format|
      if asset_group = Plate.create_sample_tubes_asset_group_and_print_barcodes(plates, barcode_printer, location, study)
        flash[:notice] = 'Created tubes and printed barcodes'
        # makes request properties partial show
        @current_user.workflow = Submission::Workflow.find_by_key("short_read_sequencing")
        @current_user.save!
        format.html { redirect_to(template_chooser_study_workflow_submissions_path(asset_group.study, @current_user.workflow )) }
        format.xml  { render :xml  => asset_group, :status => :created}
        format.json { render :json => asset_group, :status => :created}
      else
        flash[:error] = 'Failed to create sample tubes'
        format.html { redirect_to(to_sample_tubes_plates_path) }
        format.xml  { render :xml  => flash.to_xml,  :status => :unprocessable_entity }
        format.json { render :json => flash.to_json, :status => :unprocessable_entity }
      end
    end
  end

end


