# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2012,2015 Genome Research Ltd.

class SampleManifestUploadWithTagSequencesController < ApplicationController
  before_action :login_required

  def new
  end

  def create
    if params[:upload].present?
      @uploader = SampleManifest::Uploader.new(params[:upload].open, SampleManifestExcel.configuration, current_user)
      if @uploader.valid?
        if @uploader.run!
          flash[:notice] = 'Sample manifest successfully uploaded.'
          redirect_to '/sample_manifest_upload_with_tag_sequences/new'
        else
          flash.now[:error] = 'Oh dear. Your sample manifest couldn\'t be uploaded.'
          render :new
        end
      else
        flash.now[:error] = @uploader.errors.full_messages.unshift('The following error messages prevented the sample manifest from being uploaded:')
        render :new
      end
    else
      flash.now[:error] = 'No file attached'
      render :new
    end
  end
end
