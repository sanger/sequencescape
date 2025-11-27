# frozen_string_literal: true
class Sdb::SampleManifestsController < Sdb::BaseController
  before_action :set_sample_manifest_id, only: %i[show generated print_labels]
  before_action :validate_type, only: %i[new create]

  LIMIT_ERROR_LENGTH = 10_000

  def export
    @manifest = SampleManifest.find(params[:id])
    send_data(
      @manifest.generated_document.current_data,
      filename: "#{@manifest.default_filename}.xlsx",
      type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
    )
  end

  def uploaded_spreadsheet
    @manifest = SampleManifest.find(params[:id])
    send_data(
      @manifest.uploaded_document.current_data,
      filename: @manifest.uploaded_document.filename,
      type: @manifest.uploaded_document.content_type || 'application/vnd.ms-excel'
    )
  end

  def index
    pending_sample_manifests =
      SampleManifest.pending_manifests.includes(:study, :supplier, :user).paginate(page: params[:page])
    completed_sample_manifests =
      SampleManifest.completed_manifests.includes(:study, :supplier, :user).paginate(page: params[:page])
    @display_manifests = pending_sample_manifests | completed_sample_manifests
    @sample_manifests = SampleManifest.paginate(page: params[:page])
  end

  # Show the manifest
  def show
    @study_id = @sample_manifest.study_id
    @samples = @sample_manifest.samples.paginate(page: params[:page])
  end

  def new
    set_default_params
    @sample_manifest = SampleManifest.new(new_manifest_params)
    set_instance_variables
  end

  def create # rubocop:todo Metrics/AbcSize
    @sample_manifest_generator =
      SampleManifest::Generator.new(params[:sample_manifest], current_user, SampleManifestExcel.configuration)

    if @sample_manifest_generator.execute
      flash.update(@sample_manifest_generator.print_job_message)
      redirect_to sample_manifest_path(@sample_manifest_generator.sample_manifest)
    else
      flash[:error] = @sample_manifest_generator.errors.full_messages.join(', ')
      redirect_to new_sample_manifest_path
    end
  end

  def print_labels # rubocop:todo Metrics/MethodLength
    print_job =
      LabelPrinter::PrintJob.new(
        params[:printer],
        LabelPrinter::Label::SampleManifestRedirect,
        sample_manifest: @sample_manifest
      )
    if print_job.execute
      flash[:notice] = print_job.success
    else
      flash[:error] = print_job.errors.full_messages.join('; ')
    end
    redirect_back_or_to(root_path)
  end

  private

  def set_default_params
    params[:only_first_label] ||= false
    return unless SampleManifest.tube_asset_types.include?(params[:asset_type])

    params[:barcode_type] ||= '1D Barcode' # default to 1D barcode
  end

  def set_instance_variables # rubocop:todo Metrics/AbcSize
    @study_id = params[:study_id] || ''
    @studies = Study.alphabetical.pluck(:name, :id)
    @suppliers = Supplier.alphabetical.pluck(:name, :id)
    @purposes = @sample_manifest.acceptable_purposes.pluck(:name, :id)
    @rack_purposes = @sample_manifest.acceptable_rack_purposes.pluck(:name, :id) if params[:asset_type] == 'tube_rack'
    @barcode_printers = @sample_manifest.applicable_barcode_printers.pluck(:name)
    @templates = SampleManifestExcel.configuration.manifest_types.by_asset_type(params[:asset_type]).to_a
    return unless SampleManifest.tube_asset_types.include?(params[:asset_type])

    @barcode_types = Rails.application.config.tube_manifest_barcode_config[:barcode_type_labels].values.sort
  end

  def new_manifest_params
    params.permit(:study_id, :asset_type, :supplier_id, :project_id, :barcode_type)
  end

  def set_sample_manifest_id
    @sample_manifest = SampleManifest.find(params[:id])
  end

  def validate_type
    return true if SampleManifest.supported_asset_type?(params[:asset_type])

    flash[:error] = "'#{params[:asset_type]}' is not a supported manifest type."
    begin
      redirect_back_or_to(root_path)
    rescue ActionController::RedirectBackError
      redirect_to sample_manifests_path
    end
  end
end
