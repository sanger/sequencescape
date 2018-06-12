# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2012,2015 Genome Research Ltd.

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
    pending_sample_manifests = SampleManifest.pending_manifests.paginate(page: params[:page])
    completed_sample_manifests = SampleManifest.completed_manifests.paginate(page: params[:page])
    @display_manifests = pending_sample_manifests | completed_sample_manifests
    @sample_manifests = SampleManifest.paginate(page: params[:page])
  end
end
