# frozen_string_literal: true
class Admin::StudiesController < ApplicationController
  # WARNING! This filter bypasses security mechanisms in rails 4 and mimics rails 2 behviour.
  # It should be removed wherever possible and the correct Strong  Parameter options applied in its place.
  before_action :evil_parameter_hack!
  authorize_resource :study, parent: true, parent_action: :administer

  def index
    @studies = Study.alphabetical
  end

  def show
    @study = Study.find(params[:id])
    flash.now[:warning] = @study.warnings if @study.warnings.present?
  end

  def edit
    @request_types = RequestType.order(name: :asc)
    if params[:id] != '0'
      @study = Study.find(params[:id])
      flash.now[:warning] = @study.warnings if @study.warnings.present?
      render partial: 'edit', locals: { study: @study }
    else
      render nothing: true
    end
  end
  def update
    @study = Study.find(params[:id])
    flash.now[:warning] = @study.warnings if @study.warnings.present?
    flash.now[:notice] = 'Your study has been updated'
    render partial: 'manage_single_study'
  end

  # TODO: remove unneeded code
  # rubocop:todo Metrics/PerceivedComplexity, Metrics/MethodLength, Metrics/AbcSize
  def filter # rubocop:todo Metrics/CyclomaticComplexity
    filter_conditions = { approved: false } if params[:filter][:by] == 'not approved' unless params[:filter].nil?

    if ['not approved', 'all'].include?(params[:filter][:by])
      @studies = Study.where(filter_conditions).alphabetical.select { |p| p.name.include? params[:q] }
    end

    unless params[:filter].nil?
      if params[:filter][:by] == 'unallocated manager'
        @studies = Study.select { |p| p.name.include?(params[:q]) && !p.roles.map(&:name).include?('manager') }
      end
    end

    case params[:filter][:status]
    when 'open'
      @studies = @studies.select(&:active?)
    when 'closed'
      @studies = @studies.reject(&:active?)
    end
    @request_types = RequestType.order(:name)
    render partial: 'filtered_studies'
  end

  # rubocop:enable Metrics/AbcSize, Metrics/MethodLength, Metrics/PerceivedComplexity

  def managed_update # rubocop:todo Metrics/AbcSize, Metrics/MethodLength
    @study = Study.find(params[:id])

    if params[:study][:uploaded_data].present?
      Document.create!(documentable: @study, uploaded_data: params[:study][:uploaded_data])
    end
    params[:study].delete(:uploaded_data)

    ActiveRecord::Base.transaction do
      params[:study].delete(:ethically_approved) unless can? :change_ethically_approved, @study
      @study.update!(params[:study])
      flash[:notice] = 'Your study has been updated'
      redirect_to controller: 'admin/studies', action: 'update', id: @study.id
    end
  rescue ActiveRecord::RecordInvalid => e
    errors = @study.errors.full_messages
    logger.warn "Failed to update attributes: #{errors}}"
    flash.now[:error] = 'Failed to update attributes for study!'
    render action: :show, id: @study.id and return
  end

  def sort
    @studies = Study.all.sort_by(&:name)
    case params[:sort]
    when 'date'
      @studies = @studies.sort_by(&:created_at)
    when 'owner'
      @studies = @studies.sort_by(&:user_id)
    end
    render partial: 'studies'
  end
end
