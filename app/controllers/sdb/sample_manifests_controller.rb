class Sdb::SampleManifestsController < Sdb::BaseController
  before_filter :set_sample_manifest_id, :only => [:show, :generated]

  # Upload the manifest and store it for later processing
  def upload
    if (params[:sample_manifest].blank?) || (params[:sample_manifest] && params[:sample_manifest][:uploaded].blank? )
      flash[:error] = "No CSV file uploaded"
      return
    end

    @sample_manifest = SampleManifest.find_sample_manifest_from_uploaded_spreadsheet(params[:sample_manifest][:uploaded])
    if @sample_manifest.nil?
      flash[:error] = "Cannot find details about the sample manifest"
      return
    end

    @sample_manifest.update_attributes(params[:sample_manifest])
    @sample_manifest.process(current_user, params[:sample_manifest][:override] == "1")
    flash[:notice] = "Manifest being processed"
  rescue FasterCSV::MalformedCSVError
    flash[:error] = "Invalid CSV file"
  ensure
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
    @sample_manifest  = SampleManifest.new(:asset_type => params[:type])
    @studies          = Study.all.sort{ |a,b,| a.name <=> b.name }
    @suppliers        = Supplier.all.sort{ |a,b,| a.name <=> b.name }
    @barcode_printers = @sample_manifest.applicable_barcode_printers
    @templates        = @sample_manifest.applicable_templates
  end

  def create
    barcode_printer_id = params[:sample_manifest].delete(:barcode_printer)
    barcode_printer    = BarcodePrinter.find(barcode_printer_id) unless barcode_printer_id.blank?

    template         = SampleManifestTemplate.find(params[:sample_manifest].delete(:template))
    @sample_manifest = template.create!(params[:sample_manifest].merge(:user => current_user, :rapid_generation => true))

    @sample_manifest.generate
    template.generate(@sample_manifest)
    @sample_manifest.print_labels(barcode_printer)

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
