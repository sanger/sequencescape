# frozen_string_literal: true

# Provides advanced accessioning tools for administrators
class Admin::AccessioningToolsController < ApplicationController
  include ::AccessionHelper

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
  def bulk_accession
    unless accessioning_enabled?
      flash[:notice] = 'Accessioning is currently disabled. Please enable accessioning to use this tool.'
      return accessioning_not_enabled_redirect
    end

    number_of_samples = perform_bulk_accession

    flash[:success] = "Bulk accessioning complete: #{number_of_samples} samples have been sent for accessioning."
    redirect_to admin_accessioning_tools_path
  rescue Date::Error, NoMethodError
    flash[:failure] = 'An error occurred, please check that date inputs are correct.'
    redirect_to admin_accessioning_tools_path
  end

  private

  def perform_bulk_accession
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

  def updated_accessionable_samples(start_datetime, end_datetime)
    Sample
      .strict_loading
      # eager load to avoid N+1 queries when checking accessioning criteria
      .includes(:sample_metadata, studies: :study_metadata)
      .where(updated_at: start_datetime..end_datetime)
      .select(&:should_be_accessioned?)
  end
end
