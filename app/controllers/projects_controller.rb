# frozen_string_literal: true
require 'event_factory'
class ProjectsController < ApplicationController # rubocop:todo Metrics/ClassLength
  # WARNING! This filter bypasses security mechanisms in rails 4 and mimics rails 2 behviour.
  # It should be removed wherever possible and the correct Strong  Parameter options applied in its place.
  before_action :evil_parameter_hack!
  before_action :login_required
  before_action :set_variables_for_project, only: %i[show edit update destroy studies]

  # TODO: before_action :redirect_if_not_owner_or_admin, :only => [:create, :update, :destroy, :edit, :new]

  def index
    @projects = Project.alphabetical

    respond_to do |format|
      format.html
      format.xml { render xml: Project.alphabetical }
      format.json { render json: Project.alphabetical }
    end
  end

  def show
    @page_name = @project.name
    respond_to do |format|
      format.html
      format.xml
      format.json { render json: @project }
    end
  end

  def new
    @project = Project.new

    respond_to do |format|
      format.html
      format.xml { render xml: @project }
      format.json { render json: @project }
    end
  end

  def edit
    @project = Project.find(params[:id])
    @users = User.all
  end

  def create # rubocop:todo Metrics/AbcSize, Metrics/MethodLength
    # TODO[5002667]: All of this code should be in a before_create/after_create callback in the Project model ...
    @project = Project.new(params[:project])
    @project.save!

    current_user.grant_manager(@project)

    # Creates an event when a new Project is created
    EventFactory.new_project(@project, current_user)

    # TODO[5002667]: ... to here.

    flash[:notice] = 'Your project has been created'
    respond_to do |format|
      format.html { redirect_to project_path(@project) }
      format.xml { render xml: @project, status: :created, location: @project }
      format.json { render json: @project, status: :created, location: @project }
    end
  rescue ActiveRecord::RecordInvalid => e
    flash.now[:error] = 'Problems creating your new project'
    respond_to do |format|
      format.html { render action: 'new' }
      format.xml { render xml: @project.errors, status: :unprocessable_entity }
      format.json { render json: @project.errors, status: :unprocessable_entity }
    end
  end

  def update
    respond_to do |format|
      if @project.update(params[:project])
        flash[:notice] = 'Project was successfully updated.'
        format.html { redirect_to(@project) }
        format.xml { head :ok }
      else
        format.html { render action: 'edit' }
        format.xml { render xml: @project.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @project.destroy

    respond_to do |format|
      format.html { redirect_to(projects_url) }
      format.xml { head :ok }
    end
  end

  def related_studies
    @project = Project.find(params[:id])
    @studies = @project.studies

    respond_to do |format|
      format.html
      format.xml
    end
  end

  def collaborators
    @project = Project.find(params[:id])
    @all_roles = %w[owner follower manager]
    @roles = Role.where(authorizable_id: @project.id, authorizable_type: 'Project')
    @users = User.order(:first_name)
  end

  def follow # rubocop:todo Metrics/AbcSize
    @project = Project.find(params[:id])
    if current_user.follower_of?(@project)
      current_user.remove_role 'follower', @project
      flash[:notice] = "You have stopped following the '#{@project.name}' project."
    else
      current_user.grant_follower(@project)
      flash[:notice] = "You are now following the '#{@project.name}' project."
    end
    redirect_to project_path(@project)
  end

  # rubocop:todo Metrics/MethodLength
  def grant_role # rubocop:todo Metrics/AbcSize
    @user = User.find(params[:role][:user])
    @project = Project.find(params[:id])
    @role = Role.find_by(name: params[:role][:authorizable_type])

    if request.xhr?
      if params[:role]
        @user.grant_role(params[:role][:authorizable_type].to_s, @project)
        @roles = @project.roles
        flash[:notice] = 'Role added'
        render partial: 'roles', status: 200
      else
        @roles = @project.roles
        flash[:error] = 'A problem occurred while adding the role'
        render partial: 'roles', status: 500
      end
    else
      @roles = @project.roles
      flash[:error] = 'A problem occurred while adding the role'
      render partial: 'roles', status: 401
    end
  end

  # rubocop:enable Metrics/MethodLength

  # rubocop:todo Metrics/MethodLength
  def remove_role # rubocop:todo Metrics/AbcSize
    @user = User.find(params[:role][:user])
    @project = Project.find(params[:id])
    @role = Role.find_by(name: params[:role][:authorizable_type])

    if request.xhr?
      if params[:role]
        @user.remove_role(params[:role][:authorizable_type].to_s, @project)
        @roles = @project.roles
        flash[:error] = 'Role was removed'
        render partial: 'roles', status: 200
      else
        @roles = @project.roles
        flash[:error] = 'A problem occurred while removing the role'
        render partial: 'roles', status: 500
      end
    else
      @roles = @project.roles
      flash[:error] = 'A problem occurred while removing the role'
      render partial: 'roles', status: 401
    end
  end

  # rubocop:enable Metrics/MethodLength

  private

  def set_variables_for_project
    @project = Project.find(params[:id])
  end
end
