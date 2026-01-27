# frozen_string_literal: true

# rubocop:todo Metrics/ClassLength
class SamplesController < ApplicationController
  # WARNING! This filter bypasses security mechanisms in rails 4 and mimics rails 2 behviour.
  # It should be removed wherever possible and the correct Strong  Parameter options applied in its place.
  before_action :evil_parameter_hack!

  include AccessionHelper

  def index
    @samples = Sample.order(created_at: :desc).page(params[:page])
    respond_to do |format|
      format.html
      format.xml
      format.json { render json: Sample.all.to_json }
    end
  end

  def show # rubocop:disable Metrics/AbcSize
    @sample = Sample.includes(:assets, :studies).find(params[:id])
    @studies = Study.where(state: %w[pending active]).alphabetical
    @page_name = @sample.name
    @component_samples = @sample.component_samples.paginate({ page: params[:page], per_page: 25 })

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
      @sample.current_user = current_user
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
    @sample.current_user = current_user
    authorize! :update, @sample

    cleaned_params = params[:sample].permit(default_permitted_metadata_fields)

    # if consent is being withdrawn and wasn't previously, set a couple of fields
    if (cleaned_params[:sample_metadata_attributes][:consent_withdrawn] == 'true') && !@sample.consent_withdrawn
      cleaned_params[:date_of_consent_withdrawn] = DateTime.now
      cleaned_params[:user_id_of_consent_withdrawn] = current_user.id
    end

    if @sample.update(cleaned_params)
      flash[:notice] = 'Sample details have been updated'
      flash[:warning] = @sample.errors.full_messages if @sample.errors.present? # also shows warnings from accessioning
      redirect_to sample_path(@sample)
    else
      flash[:error] = 'Failed to update attributes for sample'
      flash[:warning] = @sample.errors.full_messages if @sample.errors.present?
      redirect_to edit_sample_path(@sample)
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
      accession_service = AccessionService.select_for_sample(@sample)
      xml_text = accession_service.accession_sample_xml(@sample)
      format.xml { render(xml: xml_text) }
    end
  end

  def accession # rubocop:disable Metrics/AbcSize,Metrics/CyclomaticComplexity,Metrics/MethodLength,Metrics/PerceivedComplexity
    # @sample needs to be set before initially for use in the ensure block
    @sample = Sample.find(params[:id])

    unless accessioning_enabled?
      flash[:error] = 'Accessioning is not enabled in this environment'
      redirect_to sample_path(@sample)
      return
    end
    # TODO: Y26-026 - Enforce accessioning permissions
    # unless permitted_to_accession?(@sample)
    #   flash[:error] = 'Permission required to accession this sample'
    #   redirect_to sample_path(@sample)
    #   return
    # end

    accession_action = @sample.accession_number? ? :update : :create

    if Flipper.enabled?(:y25_286_accession_individual_samples_with_sample_accessioning_job)
      # Synchronously perform accessioning job
      Accession.accession_sample(@sample, current_user, perform_now: true)
    else
      # TODO: when removing the y25_286_accession_individual_samples_with_sample_accessioning_job feature flag
      #       and this accessioning path also remove the AccessionService and ActiveRecord errors below
      @sample.validate_sample_for_accessioning!
      accession_service = AccessionService.select_for_sample(@sample)
      accession_service.submit_sample_for_user(@sample, current_user)
    end

    if accession_action == :create
      flash[:notice] = "Accession number generated: #{@sample.sample_metadata.sample_ebi_accession_number}"
    elsif accession_action == :update
      flash[:notice] = 'Accessioned metadata updated'
    end

    # Handle errors for both synchronous and asynchronous accessioning
    # When the feature flag above (y25_286_accession_individual_samples_with_sample_accessioning_job) is removed,
    # the AccessionService and ActiveRecord errors should also be removed. These errors are only raised in the old
    # synchronous accessioning code path and are not required for the updated SampleAccessioningJob path.
  rescue ActiveRecord::RecordInvalid, Accession::InternalValidationError
    flash[:error] = "Please fill in the required fields: #{@sample.errors.full_messages.join(', ')}"
    redirect_to(edit_sample_path(@sample)) # send the user to edit the sample
  rescue AccessionService::NumberNotRequired => e
    flash[:warning] = e.message || 'An accession number is not required for this study'
  rescue AccessionService::NumberNotGenerated, Accession::ExternalValidationError => e
    flash[:warning] = "No accession number was generated: #{e.message}"
  rescue AccessionService::AccessionServiceError, Accession::Error => e
    flash[:error] = "Accessioning Service Failed: #{e.message}"
  rescue Faraday::Error => e
    flash[:error] = "Accessioning failed with a network error: #{e.message}"
  ensure
    # Redirect back to where we came from if not already redirected
    redirect_back_with_anchor_or_to(sample_path(@sample), anchor: 'accession-statuses') unless performed?
  end

  private

  # Redirect back to the referer with an anchor, or to a fallback location
  # Based closely on redirect_back_or_to
  def redirect_back_with_anchor_or_to(fallback_location, anchor: '')
    referer = request.referer
    if referer.present?
      redirect_to "#{referer}##{anchor}"
    else
      redirect_to fallback_location.to_s
    end
  end

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
