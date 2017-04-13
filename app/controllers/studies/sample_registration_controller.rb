# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2012,2015 Genome Research Ltd.

class Studies::SampleRegistrationController < ApplicationController
  # WARNING! This filter bypasses security mechanisms in rails 4 and mimics rails 2 behviour.
  # It should be removed wherever possible and the correct Strong  Parameter options applied in its place.
  before_action :evil_parameter_hack!
  before_action :load_study

  def index
  end

  def create
    # We have to remap the contents of the 'sample_registrars' parameter from a hash to an array, because
    # that's what it actually is: a map from index to attributes for that SampleRegistrar instance.
    attributes = clean_params_from_check(params['sample_registrars']).each_with_object([]) do |(index_as_string, parameters), store|
      store[index_as_string.to_i] = parameters.merge(study: @study, user: current_user)
    end.compact

    @sample_registrars = SampleRegistrar.register!(attributes)
    flash[:notice] = 'Your samples have been registered'
    respond_to do |format|
      format.html { redirect_to study_path(@study) }
      format.json { render(json: flash.to_json) }
      format.xml  { render(xml: flash.to_xml) }
    end
  rescue SampleRegistrar::NoSamplesError => exception
    flash.now[:error] = 'You do not appear to have specified any samples'
    @sample_registrars = [SampleRegistrar.new]
    render(action: 'new')
  rescue SampleRegistrar::RegistrationError => exception
    flash.now[:error] = 'Your samples have not been registered'
    @sample_registrars = exception.sample_registrars
    render(action: 'new')
  end

  def new
    @sample_registrars = [SampleRegistrar.new]
  end

  def spreadsheet
    flash.now[:notice] = 'Processing your file: please wait a few minutes...'
    @sample_registrars = SampleRegistrar.from_spreadsheet(params['file'], @study, current_user)
    flash.now[:notice] = 'Your file has been processed'
    render :new
  rescue SampleRegistrar::SpreadsheetError => exception
    flash[:notice] = 'Your file has been processed'
    flash[:error] = exception.message
    redirect_to upload_study_sample_registration_index_path
  end

  def upload
    @workflow = @current_user.workflow if !@current_user.nil? && !@current_user.workflow.nil?
  end

private

  def load_study
    @study = Study.find(params[:study_id])
  end
end
