class Studies::SampleRegistrationController < ApplicationController
  before_filter :load_study

  def index
  end

  def create
    # We have to remap the contents of the 'sample_registrars' parameter from a hash to an array, because
    # that's what it actually is: a map from index to attributes for that SampleRegistrar instance.
    attributes = clean_params_from_check(params['sample_registrars']).inject([]) do |attributes,(index_as_string,parameters)|
      attributes[index_as_string.to_i] = parameters.merge(:study => @study, :user => current_user)
      attributes
    end.compact

    @sample_registrars = SampleRegistrar.register!(attributes)

    flash[:notice] = 'Your samples have been registered'
    respond_to do |format|
      format.html { redirect_to study_path(@study) }
      format.json { render(:json => flash.to_json) }
      format.xml  { render(:xml  => flash.to_xml)  }
    end
  rescue SampleRegistrar::NoSamplesError => exception
    flash[:error]      = 'You do not appear to have specified any samples'
    @sample_registrars = [ SampleRegistrar.new ]
    render(:action => 'new')
  rescue SampleRegistrar::RegistrationError => exception
    flash[:error]      = 'Your samples have not been registered'
    @sample_registrars = exception.sample_registrars
    render(:action => 'new')
  end

  def new
    if params['file']
      flash[:notice] = "Processing your file: please wait a few minutes..."
      @sample_registrars = SampleRegistrar.from_spreadsheet(params['file'], @study, current_user)
      flash[:notice] = 'Your file has been processed'
    else
      @sample_registrars = [ SampleRegistrar.new ]
    end
  rescue SampleRegistrar::SpreadsheetError => exception
    flash[:notice] = 'Your file has been processed'
    flash[:error] = exception.message
    redirect_to upload_study_sample_registration_path
  end

  def upload
    @workflow = @current_user.workflow if ! @current_user.nil? && ! @current_user.workflow.nil?
  end

private

  def load_study
    @study = Study.find(params[:study_id])
  end
end
