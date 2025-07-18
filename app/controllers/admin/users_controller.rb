# frozen_string_literal: true
class Admin::UsersController < ApplicationController # rubocop:todo Metrics/ClassLength
  # WARNING! This filter bypasses security mechanisms in rails 4 and mimics rails 2 behviour.
  # It should be removed wherever possible and the correct Strong  Parameter options applied in its place.
  before_action :evil_parameter_hack!
  before_action :setup_user, only: %i[edit show grant_user_role remove_user_role]
  authorize_resource

  def index
    @users = User.order(:login)
  end

  def show
    @page_name = @user.name
  end

  def edit
    @user = User.find(params[:id])
    @page_name = "#{action_name}: #{@user.name}"
    @all_roles = Role.keys
    @users_roles = @user.study_and_project_roles.order(name: :asc)
    @studies = Study.order(:id)
    @projects = Project.order(:id)

    respond_to do |format|
      format.js
      format.html
    end
  end

  def switch
    session[:user] = params[:id]
    redirect_to studies_url
  end

  def update # rubocop:todo Metrics/AbcSize, Metrics/MethodLength
    @user = User.find(params[:id])
    Role.general_roles.each do |role|
      params[:role] && params[:role][role.name] ? @user.grant_role(role.name) : @user.remove_role(role.name)
    end

    @user.update(params[:user]) if @user.id == params[:id].to_i
    if @user.save
      flash[:notice] = 'Profile updated'
    else
      flash[:error] = 'Problem updating profile'
    end
    redirect_to profile_path(@user)
  end

  def grant_user_role # rubocop:todo Metrics/AbcSize, Metrics/MethodLength
    if request.xhr?
      if params[:role]
        authorizable_object =
          if params[:role][:authorizable_type] == 'Project'
            Project.find(params[:role][:authorizable_id])
          else
            Study.find(params[:role][:authorizable_id])
          end
        @user.grant_role(params[:role][:authorizable_name].to_s, authorizable_object)
        @users_roles = @user.study_and_project_roles.order(name: :asc)

        flash[:notice] = 'Role added'
        render partial: 'roles', status: 200
      else
        @users_roles = @user.study_and_project_roles.order(name: :asc)
        flash[:error] = 'A problem occurred while adding the role'
        render partial: 'roles', status: 500
      end
    else
      @users_roles = @user.study_and_project_roles.sort_by(&:name)
      flash[:error] = 'A problem occurred while adding the role'
      render partial: 'roles', status: 401
    end
  end

  def remove_user_role # rubocop:todo Metrics/AbcSize, Metrics/MethodLength
    if request.xhr?
      if params[:role]
        authorizable_object =
          if params[:role][:authorizable_type] == 'project'
            Project.find(params[:role][:authorizable_id])
          else
            Study.find(params[:role][:authorizable_id])
          end
        @user.remove_role(params[:role][:authorizable_name].to_s, authorizable_object)
        @users_roles = @user.study_and_project_roles.order(name: :asc)

        flash[:error] = 'Role was removed'
        render partial: 'roles', status: 200
      else
        @users_roles = @user.study_and_project_roles.order(name: :asc)
        flash[:error] = 'A problem occurred while removing the role'
        render partial: 'roles', status: 500
      end
    else
      @users_roles = @user.study_and_project_roles.order(name: :asc)
      flash[:error] = 'A problem occurred while removing the role'
      render partial: 'roles', status: 401
    end
  end

  def filter
    if params[:q]
      @users =
        User.order(:login).where(
          'first_name LIKE :query OR last_name LIKE :query OR login LIKE :query',
          query: "%#{params[:q].downcase}%"
        )
    end

    render partial: 'users', locals: { users: @users }
  end

  private

  def setup_user
    @user = User.includes(:roles).find(params[:id])
  end
end
