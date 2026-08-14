# frozen_string_literal: true

# Provides advanced accessioning tools for administrators
class Admin::AccessioningToolsController < ApplicationController # rubocop:disable Metrics/ClassLength
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
  def bulk_accession_by_name # rubocop:disable Metrics/AbcSize
    return accessioning_not_enabled_redirect unless accessioning_enabled?

    number_of_samples = perform_bulk_accession_by_name

    flash[:success] = "Bulk accessioning complete: #{number_of_samples} samples have been sent for accessioning."
    redirect_to admin_accessioning_tools_path
  rescue SamplesNotFoundError => e
    message = "There were #{e.sample_names.count} samples not found or not eligible for accessioning including: " \
              "#{e.sample_names.join(', ')}"
    Rails.logger.warn(message)
    flash[:error] = message.truncate_words(20)
    redirect_to admin_accessioning_tools_path
  end

  # Clear the accession number for all samples in the given list of sample names
  def clear_accessions_by_name
    number_of_samples = perform_bulk_clearing_by_name

    flash[:success] =
      "Accession number clearing complete: #{number_of_samples} samples had their accession numbers cleared."
    redirect_to admin_accessioning_tools_path
  rescue SamplesNotFoundError => e
    message = "There were #{e.sample_names.count} samples not found including: #{e.sample_names.join(', ')}"
    Rails.logger.warn(message)
    flash[:error] = message.truncate_words(20)
    redirect_to admin_accessioning_tools_path
  end

  def view_sample_accessions
    sample_names = params[:sample_names].map(&:strip)
    sample_paths, accession_numbers = sample_accession_paths_and_numbers_for_names(sample_names).transpose

    render json: { sample_names:, sample_paths:, accession_numbers: }, content_type: 'application/json'
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
    samples_to_accession = accessionable_samples_by_name(parsed_sample_names)
    number_of_samples = samples_to_accession.count

    check_for_missing_samples(parsed_sample_names, samples_to_accession,
                              msg_extra: 'or are not eligible for accessioning')

    Rails.logger.info("Bulk accessioning #{number_of_samples} samples by name")
    samples_to_accession.each { |sample| Accession.accession_sample(sample, current_user) }

    number_of_samples
  end

  def perform_bulk_clearing_by_name
    samples = Sample.where(name: parsed_sample_names).includes(:sample_metadata)
    number_of_samples = samples.count

    check_for_missing_samples(parsed_sample_names, samples)

    Rails.logger.info("Clearing accession numbers for #{number_of_samples} samples by name")
    samples.each do |sample|
      authorize! :update, sample

      sample.current_user = current_user # for event logging history
      sample.clear_accession_number
    end

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

  # Returns an array of paths and accession numbers for the given sample names as an array of arrays.
  # ie: [['/samples/1', 'EGA00001000240'], ['/samples/2', 'EGA00001000241']]
  def sample_accession_paths_and_numbers_for_names(sample_names)
    samples = Sample.where(name: sample_names).includes(:sample_metadata).index_by(&:name)
    sample_names.map do |name|
      [(samples[name] ? sample_path(samples[name]) : nil), samples[name]&.ebi_accession_number]
    end
  end

  def check_for_missing_samples(sample_names, found_samples, msg_extra: '')
    missing_names = sample_names - found_samples.map(&:name)
    return unless missing_names.any?

    raise SamplesNotFoundError.new(['Samples not found', msg_extra].compact.join(' '), sample_names: missing_names)
  end

  def accessioning_not_enabled_redirect
    flash[:warning] = 'Accessioning is currently disabled. Please enable accessioning to use this tool.'
    redirect_to admin_accessioning_tools_path
  end

  def parsed_sample_names
    @parsed_sample_names ||= params[:sample_names].split(/[\n,]+/).map(&:strip).compact_blank.uniq
  end
end
