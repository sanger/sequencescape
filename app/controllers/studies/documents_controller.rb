# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2015 Genome Research Ltd.

class Studies::DocumentsController < ApplicationController
  # WARNING! This filter bypasses security mechanisms in rails 4 and mimics rails 2 behviour.
  # It should be removed wherever possible and the correct Strong  Parameter options applied in its place.
  before_action :evil_parameter_hack!
  before_action :get_study_id

  def index
    @study = Study.find(params[:study_id])
    @documents = @study.documents
  end

  def new
    @study = Study.find(params[:study_id])
  end

  def create
    document_settings = params[:document]
    document_settings[:documentable] = @study
    @document = Document.new(document_settings)
    begin
      if @document.save
        flash[:notice] = 'Document was saved okay'
        redirect_to [:admin, @study], status: 303
      else
        render action: 'new'
      end
    rescue ActiveRecord::StatementInvalid
      flash[:error] = 'Something bad happened. Perhaps karma has caught up with you?'
      redirect_to [:admin, @study], status: 303
    end
  end

  def show
    @document = Document.find(params[:id])
    send_data @document.current_data, filename: @document.filename, type: @document.content_type, disposition: 'inline'
  end

  def destroy
    @document = Document.find(params[:id])
    if @document.destroy
      flash[:notice] = 'Document was successfully deleted'
      redirect_to [:admin, @study], status: 303
    else
      flash[:error] = 'Document cannot be destroyed'
      redirect_to [:admin, @study], status: 303
    end
  end

  private

  def get_study_id
    @study = Study.find(params[:study_id])
  end
end
