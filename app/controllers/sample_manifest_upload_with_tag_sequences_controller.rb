# frozen_string_literal: true
class SampleManifestUploadWithTagSequencesController < ApplicationController
  before_action :login_required

  def new
    prepare_manifest_pagination
  end

  def create
    return error('No file attached') if params[:upload].blank?

    if upload_manifest
      @rows_with_warnings =
         @uploader.upload.rows.select { |row| row.respond_to?(:warnings) && row.warnings.any? }
      
      flash[:warnings] =
         @rows_with_warnings.flat_map { |row| row.warnings.full_messages }

      success('Sample manifest successfully uploaded.')
    else
      error('Your sample manifest couldn\'t be uploaded.')
    end
  rescue AccessionService::AccessionValidationFailed => e
    error("Your sample manifest contained invalid data and could not be uploaded: #{e.message}")
  end

  def create_uploader
    SampleManifest::Uploader.new(params[:upload], SampleManifestExcel.configuration, current_user, params[:override])
  end

  def upload_manifest
    @uploader = create_uploader
    @uploader.run!
    # @rows_with_warnings = @uploader.upload.rows.select { |row| row.warnings.any? }
  end

  def success(message)
    flash[:notice] = message
    redirect_target = (@uploader.study.present? ? sample_manifests_study_path(@uploader.study) : sample_manifests_path)

    # render :new
    redirect_to redirect_target
  end

  def error(message)
    flash.now[:error] = message
    prepare_manifest_pagination
    render :new
  end

  def prepare_manifest_pagination # rubocop:todo Metrics/MethodLength
    pending_sample_manifests =
      SampleManifest
        .pending_manifests
        .includes(:study, :supplier, :user, :uploaded_document)
        .paginate(page: params[:page])
    completed_sample_manifests =
      SampleManifest
        .completed_manifests
        .includes(:study, :supplier, :user, :uploaded_document)
        .paginate(page: params[:page])
    @display_manifests = pending_sample_manifests | completed_sample_manifests
    @sample_manifests = SampleManifest.paginate(page: params[:page])
  end
end
