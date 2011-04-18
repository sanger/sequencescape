class Sdb::SampleManifestsController < Sdb::BaseController
  before_filter :set_sample_manifest_id, :only => [:show, :generated]
  
  # Upload the manifest and store it for later processing
  def upload
    if (params[:sample_manifest].blank?) || (params[:sample_manifest] && params[:sample_manifest][:uploaded].blank? )
      flash[:error] = "No CSV file uploaded"
      redirect_to sample_manifests_path
      return
    end

    @sample_manifest = SampleManifest.find_sample_manifest_from_uploaded_spreadsheet(params[:sample_manifest][:uploaded])
    if @sample_manifest.nil?
      flash[:error] = "Cannot find details about the sample manifest"
      redirect_to sample_manifests_path
      return
    end
    
    begin
      @sample_manifest.update_attributes(params[:sample_manifest])
      @sample_manifest.process(params[:sample_manifest][:override] == "1" ? true : false, current_user )
      flash[:notice] = "Manifest being processed"
    rescue FasterCSV::MalformedCSVError
      flash[:error] = "Invalid CSV file"
    end
    redirect_to sample_manifests_path
  end

  def export
    @manifest = SampleManifest.find(params[:id])
    send_data(@manifest.generated.data, 
              :filename => "manifest_#{@manifest.id}.xls",
              :type => 'application/excel')
  end
  
  def uploaded_spreadsheet
    @manifest = SampleManifest.find(params[:id])
    send_data(@manifest.uploaded.data, 
              :filename => "manifest_#{@manifest.id}.csv",
              :type => 'application/excel')
  end
      
  def new
    @sample_manifest = SampleManifest.new
    @studies = Study.all.sort{ |a,b,| a.name <=> b.name }
    @suppliers = Supplier.all.sort{ |a,b,| a.name <=> b.name }
    
    asset_type = params[:type]
    if asset_type == "1dtube"
      @barcode_printers = BarcodePrinterType.find_by_name("1D Tube").barcode_printers
    else
      asset_type = "plate"
      @barcode_printers = BarcodePrinterType.find_by_name("96 Well Plate").barcode_printers
    end
    @barcode_printers = BarcodePrinter.find(:all, :order => "name asc") if @barcode_printers.blank?
    
   # find templates
    if asset_type.present?
      @templates = SampleManifestTemplate.find_all_by_asset_type(asset_type) + SampleManifestTemplate.find_all_by_asset_type(nil)
    else
      @templates = SampleManifestTemplate.all
    end
  end
  
  def create
    barcode_printer_id = params[:sample_manifest].delete(:barcode_printer)
    if barcode_printer_id
      barcode_printer = BarcodePrinter.find(barcode_printer_id)
    end
    @sample_manifest = SampleManifest.create!(params[:sample_manifest].merge!({ :user => current_user }))
    template = SampleManifestTemplate.find(@sample_manifest.template)
    if template.asset_type.present? 
      @sample_manifest.asset_type = template.asset_type
      @sample_manifest.save!
    end
    @sample_manifest.generate(template, barcode_printer)
    if !@sample_manifest.manifest_errors.empty?
      flash[:error] = @sample_manifest.manifest_errors.join(", ")
      @sample_manifest.destroy
      redirect_to new_sample_manifest_path
    else
      redirect_to sample_manifest_path(@sample_manifest)
    end
  end
    
  # Show the manifest
  def show
  end
  
  def index
    pending_sample_manifests = SampleManifest.pending_manifests.paginate(:page => params[:page])
    completed_sample_manifests = SampleManifest.completed_manifests.paginate(:page => params[:page])
    @display_manifests = pending_sample_manifests | completed_sample_manifests
    @sample_manifests = SampleManifest.paginate(:page => params[:page])
  end
  
  private
  def set_sample_manifest_id
    @sample_manifest = SampleManifest.find(params[:id])
  end
    
end
