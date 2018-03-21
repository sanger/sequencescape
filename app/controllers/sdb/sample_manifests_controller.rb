# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2012,2015,2016 Genome Research Ltd.

class Sdb::SampleManifestsController < Sdb::BaseController
  before_action :set_sample_manifest_id, only: [:show, :generated, :print_labels]
  before_action :validate_type, only: [:new, :create]

  LIMIT_ERROR_LENGTH = 10000

  # Upload the manifest and store it for later processing
  def upload
    if (params[:sample_manifest].blank?) || (params[:sample_manifest] && params[:sample_manifest][:uploaded].blank?)
      flash[:error] = 'No CSV file uploaded'
      return
    end

    @sample_manifest = SampleManifest.find_sample_manifest_from_uploaded_spreadsheet(params[:sample_manifest][:uploaded])
    if @sample_manifest.nil?
      flash[:error] = 'Cannot find details about the sample manifest'
      return
    end

    @sample_manifest.update_attributes(params[:sample_manifest])
    @sample_manifest.process(current_user, params[:sample_manifest][:override] == '1')
    flash[:notice] = 'Manifest being processed'
  rescue CSV::MalformedCSVError
    flash[:error] = 'Invalid CSV file'
  ensure
    redirect_to (@sample_manifest.present? ? sample_manifests_study_path(@sample_manifest.study) : sample_manifests_path)
  end

  def export
    @manifest = SampleManifest.find(params[:id])
    send_data(@manifest.generated_document.current_data,
              filename: "manifest_#{@manifest.id}.xlsx",
              type: 'application/excel')
  end

  def uploaded_spreadsheet
    @manifest = SampleManifest.find(params[:id])
    send_data(@manifest.uploaded_document.current_data,
              filename: "manifest_#{@manifest.id}.csv",
              type: 'application/excel')
  end

  def new
    params[:only_first_label] ||= false
    @sample_manifest  = SampleManifest.new(new_manifest_params)
    @study_id         = params[:study_id] || ''
    @studies          = Study.alphabetical.pluck(:name, :id)
    @suppliers        = Supplier.alphabetical.pluck(:name, :id)
    @purposes         = @sample_manifest.acceptable_purposes.pluck(:name, :id)
    @barcode_printers = @sample_manifest.applicable_barcode_printers.pluck(:name)
    @templates        = SampleManifestExcel.configuration.manifest_types.by_asset_type(params[:asset_type]).to_a
  end

  def create
    @sample_manifest_generator = SampleManifest::Generator.new(params[:sample_manifest],
                                                               current_user, SampleManifestExcel.configuration)

    if @sample_manifest_generator.execute

      flash.update(@sample_manifest_generator.print_job_message)
      redirect_to sample_manifest_path(@sample_manifest_generator.sample_manifest)
    else

      flash[:error] = @sample_manifest_generator.errors.full_messages.join(', ')
      redirect_to new_sample_manifest_path

    end
  end

  # Show the manifest
  def show
    @study_id = @sample_manifest.study_id
    @samples = @sample_manifest.samples.paginate(page: params[:page])
  end

  def index
    pending_sample_manifests = SampleManifest.pending_manifests.paginate(page: params[:page])
    completed_sample_manifests = SampleManifest.completed_manifests.paginate(page: params[:page])
    @display_manifests = pending_sample_manifests | completed_sample_manifests
    @sample_manifests = SampleManifest.paginate(page: params[:page])
  end

  def print_labels
    print_job = LabelPrinter::PrintJob.new(params[:printer],
                                           LabelPrinter::Label::SampleManifestRedirect,
                                           sample_manifest: @sample_manifest)
    if print_job.execute
      flash[:notice] = print_job.success
    else
      flash[:error] = print_job.errors.full_messages.join('; ')
    end
    redirect_back fallback_location: root_path
  end

  private

  def new_manifest_params
    params.permit(:study_id, :asset_type, :supplier_id, :project_id)
  end

  def set_sample_manifest_id
    @sample_manifest = SampleManifest.find(params[:id])
  end

  def validate_type
    return true if SampleManifest.supported_asset_type?(params[:asset_type])
    flash[:error] = "'#{params[:asset_type]}' is not a supported manifest type."
    begin
      redirect_back fallback_location: root_path
    rescue ActionController::RedirectBackError
      redirect_to sample_manifests_path
    end
  end
end
