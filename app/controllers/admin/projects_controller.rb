# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2012,2013,2015 Genome Research Ltd.
require 'event_factory'
class Admin::ProjectsController < ApplicationController
  # WARNING! This filter bypasses security mechanisms in rails 4 and mimics rails 2 behviour.
  # It should be removed wherever possible and the correct Strong  Parameter options applied in its place.
  before_action :evil_parameter_hack!
# WARNING! This filter bypasses security mechanisms in rails 4 and mimics rails 2 behviour.
# It should be removed wherever possible and the correct Strong  Parameter options applied in its place.
before_action :evil_parameter_hack!

  before_action :admin_login_required

  BY_SCOPES = {
    'not approved' => :unapproved,
    'unallocated division' => :with_unallocated_budget_division,
    'unallocated manager' => :with_unallocated_manager
  }
  BY_SCOPES.default = :scoped

  def index
    @projects = Project.alphabetical
    @request_types = RequestType.alphabetical
  end

  def show
    @project = Project.find(params[:id])
  end

  def update
   @project = Project.find(params[:id])
   flash[:notice] = 'Your project has been updated'
   render partial: 'manage_single_project'
  end

  def edit
    @request_types = RequestType.order(name: :asc)
    if params[:id] != '0'
      @project = Project.find(params[:id])
      render partial: 'edit', locals: { project: @project }
    else
      render nothing: true
    end
  end

  def filter
    filters = params[:filter] || {}

    by_scope = BY_SCOPES[filters[:by]]

    base_scope = Project.send(by_scope).in_state(filters[:status]).alphabetical

    # arel_table is used to generate the more complex like query
    projects = Project.arel_table
    scope = filters[:q].present? ? base_scope.where(projects[:name].matches("%#{filters[:q]}%")) : base_scope

    @projects = scope

    render partial: 'filtered_projects'
  end

  def managed_update
    @project = Project.find(params[:id])
    redirect_if_not_owner_or_admin(@project)

    unless params[:project][:uploaded_data].blank?
      document_settings = {}
      document_settings[:uploaded_data] = params[:project][:uploaded_data]
      doc = Document.create(document_settings)
      doc.documentable = @project
      doc.save
    end
    params[:project].delete(:uploaded_data)

    pre_approved = @project.approved?

    if @project.update_attributes(params[:project])
      if pre_approved == false && @project.approved == true
        EventFactory.project_approved(@project, current_user)
      end

      flash[:notice] = 'Your project has been updated'
      redirect_to controller: 'admin/projects', action: 'update', id: @project.id
    else
      logger.warn "Failed to update attributes: #{@project.errors.map { |e| e.to_s }}"
      flash[:error] = 'Failed to update attributes for project!'
      render action: :show, id: @project.id and return
    end
  end

  def sort
    @projects = Project.all.sort_by { |project| project.name }
    if params[:sort] == 'date'
      @projects = @projects.sort_by { |project| project.created_at }
    elsif params[:sort] == 'owner'
      @projects = @projects.sort_by { |project| project.user_id }
    end
    render partial: 'projects'
  end

  private

  def redirect_if_not_owner_or_admin(project)
    unless current_user.owner?(project) or current_user.is_administrator?
      flash[:error] = "Project details can only be altered by the owner (#{project.user.login}) or an administrator"
      redirect_to project_path(project)
    end
  end
end
