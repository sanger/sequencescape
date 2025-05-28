# frozen_string_literal: true
class SampleManifestUploadWithTagSequencesController < ApplicationController
  before_action :login_required

  def new
    prepare_manifest_pagination
  end

  def create
    return error('No file attached') unless params[:upload].present?

    @uploader = create_uploader

    begin
      upload_succeeded = @uploader.run!
    rescue Sample::AccessionValidationFailed => e
      return error("Your sample manifest contained invalid data and could not be uploaded: #{e.message}")
    end

    if upload_succeeded
      success('Sample manifest successfully uploaded.')
    else
      error('Your sample manifest couldn\'t be uploaded.')
    end
  end

  def create_uploader
    SampleManifest::Uploader.new(params[:upload], SampleManifestExcel.configuration, current_user, params[:override])
  end

  def success(message)
    flash[:notice] = message
    redirect_target = (@uploader.study.present? ? sample_manifests_study_path(@uploader.study) : sample_manifests_path)

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
