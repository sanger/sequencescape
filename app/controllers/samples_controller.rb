# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2012,2013,2014,2015,2016 Genome Research Ltd.

class SamplesController < ApplicationController
  # WARNING! This filter bypasses security mechanisms in rails 4 and mimics rails 2 behviour.
  # It should be removed wherever possible and the correct Strong  Parameter options applied in its place.
  before_action :evil_parameter_hack!
  include XmlCacheHelper::ControllerHelper

  before_action :admin_login_required, only: [:administer, :destroy]

  def index
    @samples = Sample.order(created_at: :desc).page(params[:page])
    respond_to do |format|
      format.html
      format.xml
      format.json { render json: Sample.all.to_json }
    end
  end

  def new
    @sample = Sample.new
    @workflows = Submission::Workflow.all
    @studies = Study.alphabetical
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
        flash[:notice] = 'Sample successfully created'
        format.html { redirect_to sample_path(@sample) }
        format.xml  { render xml: @sample, status: :created, location: @sample }
        format.json  { render json: @sample, status: :created, location: @sample }
      else
        @workflows = Submission::Workflow.all
        flash[:error] = 'Problems creating your new sample'
        format.html { render action: :new }
        format.xml  { render xml: @sample.errors, status: :unprocessable_entity }
        format.json { render json: @sample.errors, status: :unprocessable_entity }
      end
    end
  end

  def show
    @sample  = Sample.includes(:assets, :studies).find(params[:id])
    @studies = Study.where(state: ['pending', 'active']).alphabetical

    respond_to do |format|
      format.html
      format.xml { render layout: false }
      format.json { render json: @sample.to_json }
    end
  end

  def release
    @sample = Sample.find(params[:id])
    redirect_if_not_owner_or_admin_otherwise do
      if @sample.released?
        flash[:notice] = "Sample '#{@sample.name}' already publically released"
      else
        @sample.release
        flash[:notice] = "Sample '#{@sample.name}' publically released"
      end
      redirect_to sample_path(@sample)
    end
  end

  def edit
    @sample = Sample.find(params[:id])
    redirect_if_not_owner_or_admin_otherwise do
      if @sample.released? && !current_user.is_administrator?
        flash[:error] = 'Cannot edit publically released sample'
        redirect_to sample_path(@sample)
        return
      end

      respond_to do |format|
        format.html
        format.xml  { render xml: @samples.to_xml }
        format.json { render json: @samples.to_json }
      end
    end
  end

  def update
    @sample = Sample.find(params[:id])
    redirect_if_not_owner_or_admin_otherwise do
      cleaned_params = clean_params_from_check(params[:sample]).permit(default_permitted_metadata_fields)
      if @sample.update_attributes(cleaned_params)
        flash[:notice] = 'Sample details have been updated'
        redirect_to sample_path(@sample)
      else
        @workflows = Submission::Workflow.all
        flash[:error] = 'Failed to update attributes for sample'
        render action: 'edit', id: @sample.id
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
    StudySample.find_by(study_id: params[:study_id], sample_id: params[:id]).destroy
    flash[:notice] = "Sample was removed from study #{study.name.humanize}"
    redirect_to sample_path(sample)
  end

  def show_accession
    @sample = Sample.find(params[:id])
    respond_to do |format|
      xml_text = @sample.accession_service.accession_sample_xml(@sample)
      format.xml { render(text: xml_text) }
    end
  end

  def accession
    @sample = Sample.find(params[:id])
    @sample.validate_ena_required_fields!
    @sample.accession_service.submit_sample_for_user(@sample, current_user)

    flash[:notice] = "Accession number generated: #{@sample.sample_metadata.sample_ebi_accession_number}"
    redirect_to(sample_path(@sample))
  rescue ActiveRecord::RecordInvalid => exception
    flash[:error] = "Please fill in the required fields: #{@sample.errors.full_messages.join(', ')}"
    redirect_to(edit_sample_path(@sample))
  rescue AccessionService::NumberNotRequired => exception
    flash[:warning] = exception.message || 'An accession number is not required for this study'
    redirect_to(sample_path(@sample))
  rescue AccessionService::NumberNotGenerated => exception
    flash[:warning] = "No accession number was generated: #{exception.message}"
    redirect_to(sample_path(@sample))
  rescue AccessionService::AccessionServiceError => exception
    flash[:error] = exception.message
    redirect_to(sample_path(@sample))
  end

   def taxon_lookup
     if params[:term]
       url = configatron.taxon_lookup_url + "/esearch.fcgi?db=taxonomy&term=#{params[:term].gsub(/\s/, '_')}"
     elsif params[:id]
       url = configatron.taxon_lookup_url + "/efetch.fcgi?db=taxonomy&mode=xml&id=#{params[:id]}"
     else return
     end

     rc = RestClient::Resource.new(URI.parse(url).to_s)
     if configatron.disable_web_proxy == true
       RestClient.proxy = ''
     elsif not configatron.proxy.blank?
       RestClient.proxy = configatron.proxy
       rc.headers['User-Agent'] = 'Internet Explorer 5.0'
     end
     # rc.verbose = true
     body = rc.get.body

     respond_to do |format|
       format.js { render text: body }
       format.xml { render text: body }
       #      format.html {render :nothing}
     end
   end

private

  def default_permitted_metadata_fields
    { sample_metadata_attributes: [
      :organism, :gc_content, :cohort, :gender, :country_of_origin, :geographical_region, :ethnicity, :dna_source,
      :volume, :supplier_plate_id, :mother, :father, :replicate, :sample_public_name, :sample_common_name,
      :sample_strain_att, :sample_taxon_id, :sample_ebi_accession_number, :sample_sra_hold,
      :sample_description, :sibling, :is_resubmitted, :date_of_sample_collection, :date_of_sample_extraction,
      :sample_extraction_method, :sample_purified, :purification_method, :concentration, :concentration_determined_by,
      :sample_type, :sample_storage_conditions, :supplier_name, :reference_genome_id, :genotype, :phenotype, :age,
      :developmental_stage, :cell_type, :disease_state, :compound, :dose, :immunoprecipitate, :growth_condition,
      :rnai, :organism_part, :time_point, :disease, :subject, :treatment, :donor_id
    ] }
  end

  def redirect_if_not_owner_or_admin_otherwise
    return yield if current_user.owner?(@sample) or current_user.is_administrator? or current_user.is_manager?
    flash[:error] = 'Sample details can only be altered by the owner or an administrator or manager'
    redirect_to sample_path(@sample)
  end
end
