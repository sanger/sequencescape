class SamplesController < ApplicationController
  include XmlCacheHelper::ControllerHelper

  #require 'curb'

  before_filter :admin_login_required, :only => [ :administer, :destroy ]

  def index
    @samples = Sample.paginate :page => params[:page], :order => 'created_at DESC'
    respond_to do |format|
      format.html
      format.xml
      format.json { render :json => Sample.all.to_json }
    end
  end

  def new
    @sample = Sample.new
    @workflows  = Submission::Workflow.all
    @studies   = Study.all.sort_by {|p| p.name }
  end

  def create
    @sample = Sample.new(params[:sample])

    study_id = params[:study_id]
    if study_id
      study = Study.find(study_id)
      study.samples << @sample
    end

    respond_to do |format|
      if @sample.save
        flash[:notice] = "Sample successfully created"
        format.html { redirect_to sample_path(@sample) }
        format.xml  { render :xml => @sample, :status => :created, :location => @sample }
        format.json  { render :json => @sample, :status => :created, :location => @sample }
      else
        @workflows = Submission::Workflow.all
        flash[:error] = "Problems creating your new sample"
        format.html { render :action => :new }
        format.xml  { render :xml => @sample.errors, :status => :unprocessable_entity }
        format.json  { render :json => @sample.errors, :status => :unprocessable_entity }
      end
    end
  end

  def show
    @sample  = Sample.find(params[:id], :include => :assets)
    @studies = Study.all(:conditions => ["state = ? OR state = ?", "pending", "active"], :order => :name)

    respond_to do |format|
      format.html
      format.xml { cache_xml_response(@sample) }
      format.json { render :json => @sample.to_json }
    end
  end

  def release
    @sample = Sample.find(params[:id])
    redirect_if_not_owner_or_admin_otherwise do
      unless @sample.released?
        @sample.release
        flash[:notice] = "Sample '#{@sample.name}' publically released"
      else
        flash[:notice] = "Sample '#{@sample.name}' already publically released"
      end
      redirect_to sample_path(@sample)
    end
  end


  def edit
    @sample = Sample.find(params[:id])
    redirect_if_not_owner_or_admin_otherwise do
      if @sample.released? && ! current_user.is_administrator?
        flash[:error] = "Cannot edit publically released sample"
        redirect_to sample_path(@sample)
        return
      end

      respond_to do |format|
        format.html
        format.xml  { render :xml => @samples.to_xml }
        format.json { render :json => @samples.to_json }
      end
    end
  end


  def update
    @sample = Sample.find(params[:id])
    redirect_if_not_owner_or_admin_otherwise do
      begin
        cleaned_params  = clean_params_from_check(params[:sample])
        @sample.update_attributes!(cleaned_params)
        flash[:notice] = "Sample details have been updated"
        redirect_to sample_path(@sample)
      rescue ActiveRecord::RecordInvalid => exception
        @workflows = Submission::Workflow.all
        flash[:error] = "Failed to update attributes for sample"
        render :action => "edit", :id => @sample.id
      end
    end
  end

  def history
    @sample = Sample.find(params[:id])
    respond_to do |format|
      format.html
    end
  end

  def add_to_study
    sample = Sample.find(params[:id])
    study = Study.find(params[:study][:id])
    study.samples << sample
    redirect_to sample_path(sample)
  rescue ActiveRecord::RecordInvalid => exception
    flash[:error] = exception.record.errors.full_messages
    redirect_to sample_path(sample)
  end

  def remove_from_study
    study = Study.find(params[:study_id])
    sample = Sample.find(params[:id])
    StudySample.find(:first, :conditions=>{:study_id=>params[:study_id],:sample_id=>params[:id]}).destroy
    flash[:notice] = "Sample was removed from study #{study.name.humanize}"
    redirect_to sample_path(sample)
  end

  def show_accession
    @sample = Sample.find(params[:id])
    respond_to do |format|
      xml_text =@sample.accession_service.accession_sample_xml(@sample)
      format.xml  { render(:text => xml_text) }
    end
  end

  def accession
    @sample = Sample.find(params[:id])
    @sample.validate_ena_required_fields!
    @sample.accession_service.submit_sample_for_user(@sample, current_user)

    flash[:notice] = "Accession number generated: #{ @sample.sample_metadata.sample_ebi_accession_number }"
    redirect_to(sample_path(@sample))
  rescue ActiveRecord::RecordInvalid => exception
    flash[:error] = "Please fill in the required fields: #{@sample.errors.full_messages.join(', ')}"
    redirect_to(edit_sample_path(@sample))
  rescue AccessionService::NumberNotRequired => exception
    flash[:warning] = 'An accession number is not required for this study'
    redirect_to(sample_path(@sample))
  rescue AccessionService::NumberNotGenerated => exception
    flash[:warning] = 'No accession number was generated'
    redirect_to(sample_path(@sample))
  rescue AccessionService::AccessionServiceError => exception
    flash[:error] = exception.message
    redirect_to(sample_path(@sample))
  end

   def taxon_lookup
     if params[:term]
       url= configatron.taxon_lookup_url+"/esearch.fcgi?db=taxonomy&term=#{params[:term].gsub(/\s/, '_')}"
     elsif params[:id]
       url = configatron.taxon_lookup_url+"/efetch.fcgi?db=taxonomy&mode=xml&id=#{params[:id]}"
     else return
     end

     rc = RestClient::Resource.new(URI.parse(url).to_s)
     if configatron.disable_web_proxy == true
       RestClient.proxy = ''
     elsif not configatron.proxy.blank?
       RestClient.proxy= configatron.proxy
       rc.headers["User-Agent"] = "Internet Explorer 5.0"
     end
     #rc.verbose = true
     body = rc.get.body

     respond_to do |format|
       format.js {render :text =>body}
       format.xml {render :text =>body}
       #      format.html {render :nothing}
     end
   end

private

  def redirect_if_not_owner_or_admin_otherwise(&block)
    return yield if current_user.owner?(@sample) or current_user.is_administrator? or current_user.is_manager?
    flash[:error] = "Sample details can only be altered by the owner or an administrator or manager"
    redirect_to sample_path(@sample)
  end
end
