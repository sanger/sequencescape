# frozen_string_literal: true
require 'event_factory'
class Admin::ProjectsController < ApplicationController
  # WARNING! This filter bypasses security mechanisms in rails 4 and mimics rails 2 behviour.
  # It should be removed wherever possible and the correct Strong  Parameter options applied in its place.
  before_action :evil_parameter_hack!
  authorize_resource :project, parent: true, parent_action: :administer

  BY_SCOPES = {
    'not approved' => :unapproved,
    'unallocated division' => :with_unallocated_budget_division,
    'unallocated manager' => :with_unallocated_manager,
    'all' => :all
  }.freeze

  def index
    @projects = Project.alphabetical
    @request_types = RequestType.alphabetical
  end

  def show
    @project = Project.find(params[:id])
  end

  def edit
    if params[:id] == '0'
      render nothing: true
    else
      @project = Project.find(params[:id])
      render partial: 'edit', locals: { project: @project }
    end
  end

  def update
    @project = Project.find(params[:id])
    flash.now[:notice] = 'Your project has been updated'
    render partial: 'manage_single_project'
  end

  def filter # rubocop:todo Metrics/AbcSize
    filters = params[:filter] || {}

    by_scope = BY_SCOPES.fetch(filters[:by], :all)

    base_scope = Project.send(by_scope).in_state(filters[:status]).alphabetical

    # arel_table is used to generate the more complex like query
    projects = Project.arel_table
    scope = filters[:q].present? ? base_scope.where(projects[:name].matches("%#{filters[:q]}%")) : base_scope

    @projects = scope

    render partial: 'filtered_projects'
  end

  helper_method def project_scopes
    BY_SCOPES.keys
  end

  # rubocop:todo Metrics/MethodLength
  def managed_update # rubocop:todo Metrics/AbcSize
    @project = Project.find(params[:id])
    authorize! :managed_update, @project

    if params[:project][:uploaded_data].present?
      document_settings = {}
      document_settings[:uploaded_data] = params[:project][:uploaded_data]
      doc = Document.create(document_settings)
      doc.documentable = @project
      doc.save
    end
    params[:project].delete(:uploaded_data)

    pre_approved = @project.approved?

    if @project.update(params[:project])
      EventFactory.project_approved(@project, current_user) if pre_approved == false && @project.approved == true

      flash[:notice] = 'Your project has been updated'
      redirect_to controller: 'admin/projects', action: 'update', id: @project.id
    else
      logger.warn "Failed to update attributes: #{@project.errors.map(&:to_s)}"
      flash[:error] = 'Failed to update attributes for project!'
      render action: :show, id: @project.id and return
    end
  end

  # rubocop:enable Metrics/MethodLength

  def sort
    @projects = Project.all.sort_by(&:name)
    case params[:sort]
    when 'date'
      @projects = @projects.sort_by(&:created_at)
    when 'owner'
      @projects = @projects.sort_by(&:user_id)
    end
    render partial: 'projects'
  end
end
