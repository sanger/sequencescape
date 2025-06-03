# frozen_string_literal: true

require 'exception_notification'

# rubocop:todo Metrics/ClassLength
class SamplesController < ApplicationController
  # WARNING! This filter bypasses security mechanisms in rails 4 and mimics rails 2 behviour.
  # It should be removed wherever possible and the correct Strong  Parameter options applied in its place.
  before_action :evil_parameter_hack!

  def index
    @samples = Sample.order(created_at: :desc).page(params[:page])
    respond_to do |format|
      format.html
      format.xml
      format.json { render json: Sample.all.to_json }
    end
  end

  def show
    @sample = Sample.includes(:assets, :studies).find(params[:id])
    @studies = Study.where(state: %w[pending active]).alphabetical

    respond_to do |format|
      format.html
      format.xml { render layout: false }
      format.json { render json: @sample.to_json }
    end
  end
  def new
    @sample = Sample.new
    @studies = Study.alphabetical
  end

  def edit # rubocop:todo Metrics/AbcSize, Metrics/MethodLength
    @sample = Sample.find(params[:id])
    authorize! :update, @sample

    if @sample.released? && cannot?(:update_released, @sample)
      flash[:error] = 'Cannot edit publicly released sample'
      redirect_to sample_path(@sample)
      return
    end

    respond_to do |format|
      format.html
      format.xml { render xml: @samples.to_xml }
      format.json { render json: @samples.to_json }
    end
  end
  def create # rubocop:todo Metrics/AbcSize, Metrics/MethodLength
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
        format.xml { render xml: @sample, status: :created, location: @sample }
        format.json { render json: @sample, status: :created, location: @sample }
      else
        flash[:error] = 'Problems creating your new sample'
        format.html { render action: :new }
        format.xml { render xml: @sample.errors, status: :unprocessable_entity }
        format.json { render json: @sample.errors, status: :unprocessable_entity }
      end
    end
  end

  def release
    @sample = Sample.find(params[:id])
    authorize! :release, @sample

    if @sample.released?
      flash[:notice] = "Sample '#{@sample.name}' already publically released"
    else
      @sample.release
      flash[:notice] = "Sample '#{@sample.name}' publically released"
    end
    redirect_to sample_path(@sample)
  end

  # rubocop:todo Metrics/MethodLength
  def update # rubocop:todo Metrics/AbcSize
    @sample = Sample.find(params[:id])
    authorize! :update, @sample

    cleaned_params = params[:sample].permit(default_permitted_metadata_fields)

    # if consent is being withdrawn and wasn't previously, set a couple of fields
    if (cleaned_params[:sample_metadata_attributes][:consent_withdrawn] == 'true') && !@sample.consent_withdrawn
      cleaned_params[:date_of_consent_withdrawn] = DateTime.now
      cleaned_params[:user_id_of_consent_withdrawn] = current_user.id
    end

    # Show warnings from accessioning
    flash.now[:warning] = @sample.errors if @sample.errors.present?

    if @sample.update(cleaned_params)
      flash[:notice] = 'Sample details have been updated'
      redirect_to sample_path(@sample)
    else
      flash[:error] = 'Failed to update attributes for sample'
      render action: 'edit', id: @sample.id
    end
  end

  # rubocop:enable Metrics/MethodLength

  def history
    @sample = Sample.find(params[:id])
    respond_to { |format| format.html }
  end

  def add_to_study # rubocop:todo Metrics/AbcSize
    sample = Sample.find(params[:id])
    study = Study.find(params[:study][:id])
    study.samples << sample
    redirect_to sample_path(sample)
  rescue ActiveRecord::RecordInvalid => e
    flash[:error] = e.record.errors.full_messages
    redirect_to sample_path(sample)
  end

  def remove_from_study # rubocop:todo Metrics/AbcSize
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

  # rubocop:todo Metrics/MethodLength
  def accession # rubocop:todo Metrics/AbcSize
    @sample = Sample.find(params[:id])
    @sample.validate_ena_required_fields!
    @sample.accession_service.submit_sample_for_user(@sample, current_user)

    flash[:notice] = "Accession number generated: #{@sample.sample_metadata.sample_ebi_accession_number}"
  rescue ActiveRecord::RecordInvalid => e
    flash[:error] = "Please fill in the required fields: #{@sample.errors.full_messages.join(', ')}"
  rescue AccessionService::NumberNotRequired => e
    flash[:warning] = e.message || 'An accession number is not required for this study'
  rescue AccessionService::NumberNotGenerated => e
    flash[:warning] = "No accession number was generated: #{e.message}"
  rescue AccessionService::AccessionServiceError => e
    flash[:error] = "Accessioning Service Failed: #{e.message}"
  ensure
    redirect_to(sample_path(@sample))
  end

  # rubocop:enable Metrics/MethodLength

  # rubocop:todo Metrics/MethodLength
  def taxon_lookup # rubocop:todo Metrics/AbcSize
    if params[:term]
      url = configatron.taxon_lookup_url + "/esearch.fcgi?db=taxonomy&term=#{params[:term].gsub(/\s/, '_')}"
    elsif params[:id]
      url = configatron.taxon_lookup_url + "/efetch.fcgi?db=taxonomy&mode=xml&id=#{params[:id]}"
    else
      return
    end

    rc = RestClient::Resource.new(URI.parse(url).to_s)
    if configatron.disable_web_proxy == true
      RestClient.proxy = nil
    elsif configatron.fetch(:proxy).present?
      RestClient.proxy = configatron.proxy
      rc.headers['User-Agent'] = 'Internet Explorer 5.0'
    elsif ENV['http_proxy'].present?
      RestClient.proxy = ENV['http_proxy']
    end

    # rc.verbose = true
    body = rc.get.body

    respond_to do |format|
      format.js { render plain: body }
      format.xml { render plain: body }
      #      format.html {render :nothing}
    end
  end

  # rubocop:enable Metrics/MethodLength

  private

  def default_permitted_metadata_fields
    {
      sample_metadata_attributes: %i[
        consent_withdrawn
        organism
        gc_content
        cohort
        gender
        country_of_origin
        geographical_region
        ethnicity
        dna_source
        volume
        mother
        father
        replicate
        sample_public_name
        sample_common_name
        sample_strain_att
        sample_taxon_id
        sample_ebi_accession_number
        sample_sra_hold
        sample_description
        sibling
        is_resubmitted
        date_of_sample_collection
        date_of_sample_extraction
        sample_extraction_method
        sample_purified
        purification_method
        concentration
        concentration_determined_by
        sample_type
        sample_storage_conditions
        supplier_name
        reference_genome_id
        genotype
        phenotype
        age
        developmental_stage
        cell_type
        disease_state
        compound
        dose
        immunoprecipitate
        growth_condition
        rnai
        organism_part
        time_point
        disease
        subject
        treatment
        donor_id
      ]
    }
  end
end
# rubocop:enable Metrics/ClassLength
