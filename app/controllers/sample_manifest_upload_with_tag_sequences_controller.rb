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
    if params[:uploaded].blank?
      flash[:error] = 'No CSV file uploaded'
      return
    end

    @sample_manifest = SampleManifest.find_sample_manifest_from_uploaded_spreadsheet(params[:uploaded])
    if @sample_manifest.nil?
      flash[:error] = 'Cannot find details about the sample manifest'
      return
    end

    @sample_manifest.update(uploaded: params[:uploaded])
    @sample_manifest.process(current_user, params[:override] == '1')
    flash[:notice] = 'Manifest being processed'
  rescue CSV::MalformedCSVError
    flash[:error] = 'Invalid CSV file'
  ensure
    redirect_to @sample_manifest.present? ? sample_manifests_study_path(@sample_manifest.study) : sample_manifests_path
  end
end
