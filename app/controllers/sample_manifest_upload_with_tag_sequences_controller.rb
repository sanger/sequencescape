class SampleManifestUploadWithTagSequencesController < ApplicationController
  before_action :login_required

  def new
    prepare_manifest_pagination
  end

  def create
    if params[:upload].present?
      @uploader = SampleManifest::Uploader.new(params[:upload].open, SampleManifestExcel.configuration, current_user, params[:override])
      if @uploader.valid?
        if @uploader.run!
          flash[:notice] = 'Sample manifest successfully uploaded.'
          redirect_to '/sample_manifest_upload_with_tag_sequences/new'
        else
          flash.now[:error] = 'Your sample manifest couldn\'t be uploaded.'
          prepare_manifest_pagination
          render :new
        end
      else
        flash.now[:error] = @uploader.errors.full_messages.unshift('The following error messages prevented the sample manifest from being uploaded:')
        prepare_manifest_pagination
        render :new
      end
    else
      flash.now[:error] = 'No file attached'
      prepare_manifest_pagination
      render :new
    end
  end

  def prepare_manifest_pagination
    pending_sample_manifests = SampleManifest.pending_manifests.includes(:study, :supplier, :user, :uploaded_document).paginate(page: params[:page])
    completed_sample_manifests = SampleManifest.completed_manifests.includes(:study, :supplier, :user, :uploaded_document).paginate(page: params[:page])
    @display_manifests = pending_sample_manifests | completed_sample_manifests
    @sample_manifests = SampleManifest.paginate(page: params[:page])
  end
end
