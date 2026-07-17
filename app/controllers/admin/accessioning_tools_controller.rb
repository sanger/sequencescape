# frozen_string_literal: true

# Provides advanced accessioning tools for administrators
class Admin::AccessioningToolsController < ApplicationController
  include ::AccessionHelper

  class SamplesNotFoundError < RuntimeError
    attr_reader :sample_names

    def initialize(message, sample_names: [])
      super(message)
      @sample_names = sample_names
    end
  end

  def index
  end

  def bulk_accession_preview
    start_datetime, end_datetime = date_range_from_params

    samples_to_accession = updated_accessionable_samples(start_datetime, end_datetime)

    render json: {
      start_datetime: start_datetime.iso8601, # informational
      end_datetime: end_datetime.iso8601, # informational
      samples_count: samples_to_accession.count,
      studies_count: samples_to_accession.map(&:studies).flatten.uniq.count
    }, content_type: 'application/json'
  rescue Date::Error, NoMethodError
    message = 'Invalid dates provided. Please provide valid start_date and end_date in YYYY-MM-DD format.'
    render json: { error: message }, status: :bad_request, content_type: 'application/json'
  end

  # Accession all samples which have been modified within the date window
  def bulk_accession_by_date
    return accessioning_not_enabled_redirect unless accessioning_enabled?

    number_of_samples = perform_bulk_accession_by_date

    flash[:success] = "Bulk accessioning complete: #{number_of_samples} samples have been sent for accessioning."
    redirect_to admin_accessioning_tools_path
  rescue Date::Error, NoMethodError
    flash[:error] = 'An error occurred, please check that date inputs are correct.'
    redirect_to admin_accessioning_tools_path
  end

  # Accession all samples in the given list of sample names
  def bulk_accession_by_name
    return accessioning_not_enabled_redirect unless accessioning_enabled?

    number_of_samples = perform_bulk_accession_by_name

    flash[:success] = "Bulk accessioning complete: #{number_of_samples} samples have been sent for accessioning."
    redirect_to admin_accessioning_tools_path
  rescue SamplesNotFoundError => e
    Rails.logger.warn("#{e.sample_names.count} samples not found or not eligible for accessioning: " \
                      "#{e.sample_names.join(', ')}")
    flash[:error] = "The were #{e.sample_names.count} samples not found or not eligible for accessioning " \
                    "including: #{e.sample_names.take(5).join(', ')}"
    redirect_to admin_accessioning_tools_path
  end

  def view_sample_accessions
    sample_names = params[:sample_names].map(&:strip)
    accession_numbers = sample_accession_numbers_for_names(sample_names)

    render json: { sample_names:, accession_numbers: }, content_type: 'application/json'
  end

  private

  def perform_bulk_accession_by_date
    start_datetime, end_datetime = date_range_from_params

    samples_to_accession = updated_accessionable_samples(start_datetime, end_datetime)
    number_of_samples = samples_to_accession.count

    Rails.logger.info(
      "Bulk accessioning #{number_of_samples} samples updated between #{start_datetime} and #{end_datetime}"
    )

    samples_to_accession.each { |sample| Accession.accession_sample(sample, current_user) }

    number_of_samples
  end

  def date_range_from_params
    start_datetime = params[:start_date].to_date.beginning_of_day
    end_datetime = params[:end_date].to_date.end_of_day

    [start_datetime, end_datetime]
  end

  def perform_bulk_accession_by_name
    sample_names = params[:sample_names].split(/[\n,]+/).map(&:strip).compact_blank.uniq
    samples_to_accession = accessionable_samples_by_name(sample_names)

    unaccessionable_sample_names = sample_names - samples_to_accession.map(&:name)
    if unaccessionable_sample_names.any?
      raise SamplesNotFoundError.new(
        'Samples not found or are not eligible for accessioning',
        sample_names: unaccessionable_sample_names
      )
    end

    number_of_samples = samples_to_accession.count

    Rails.logger.info("Bulk accessioning #{number_of_samples} samples by name")

    samples_to_accession.each { |sample| Accession.accession_sample(sample, current_user) }

    number_of_samples
  end

  def updated_accessionable_samples(start_datetime, end_datetime)
    Sample
      .strict_loading
      # eager load to avoid N+1 queries when checking accessioning criteria
      .includes(:sample_metadata, studies: :study_metadata)
      .where(updated_at: start_datetime..end_datetime)
      .select(&:should_be_accessioned?)
  end

  def accessionable_samples_by_name(sample_names)
    Sample
      .strict_loading
      # eager load to avoid N+1 queries when checking accessioning criteria
      .includes(:sample_metadata, studies: :study_metadata)
      .where(name: sample_names)
      .select(&:should_be_accessioned?)
  end

  def sample_accession_numbers_for_names(sample_names)
    samples = Sample.where(name: sample_names).includes(:sample_metadata).index_by(&:name)
    sample_names.map { |name| samples[name]&.ebi_accession_number }
  end

  def accessioning_not_enabled_redirect
    flash[:notice] = 'Accessioning is currently disabled. Please enable accessioning to use this tool.'
    redirect_to admin_accessioning_tools_path
  end
end
