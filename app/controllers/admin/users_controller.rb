class Admin::UsersController < ApplicationController
  before_filter :admin_login_required
  before_filter :setup_user, :only => [:edit, :show, :grant_user_role, :remove_user_role]

  def index
    @users = User.all(:order => "login ASC")
  end

  def edit
    @user_roles = @user.roles.select{|r| r.name == "administrator" || r.name == "manager" || r.name == "internal"}
    @all_roles = Role.all(:select => "distinct `name`")
    @users_roles = @user.study_and_project_roles.sort_by(&:name)
    @studies = Study.all(:order => :id)
    @projects = Project.all(:order => :id)

    respond_to do |format|
      format.js
      format.html
    end
  end

  def show
  end

  def switch
    session[:user] = params[:id]
    redirect_to studies_url
  end

  def update
    @user = User.find(params[:id])

    Role.general_roles.each do |role|
      if params[:role] && params[:role][role.name]
        @user.has_role(role.name)
      else
        @user.has_no_role(role.name)
      end
    end

    if @user.id == params[:id].to_i
      @user.update_attributes(params[:user])
    end
    if @user.save
      flash[:notice] = "Profile updated"
    else
      flash[:error] = "Problem updating profile"
    end
    redirect_to profile_path(@user)
  end

  def grant_user_role
    if request.xhr?
      if params[:role]
        if params[:role][:authorizable_type] == "Project"
          authorizable_object = Project.find(params[:role][:authorizable_id])
        else
          authorizable_object = Study.find(params[:role][:authorizable_id])
        end
        @user.has_role(params[:role][:authorizable_name].to_s, authorizable_object)
        @users_roles = @user.study_and_project_roles.sort_by(&:name)

        flash[:notice] = "Role added"
        render :partial => "roles", :status => 200
      else
        @users_roles = @user.study_and_project_roles.sort_by(&:name)
        flash[:error] = "A problem occurred while adding the role"
        render :partial => "roles", :status => 500
      end
    else
      @users_roles = @user.study_and_project_roles.sort_by(&:name)
      flash[:error] = "A problem occurred while adding the role"
      render :partial => "roles", :status => 401
    end
  end

  def remove_user_role
    if request.xhr?
      if params[:role]
        if params[:role][:authorizable_type] == "project"
          authorizable_object = Project.find(params[:role][:authorizable_id])
        else
          authorizable_object = Study.find(params[:role][:authorizable_id])
        end
        @user.has_no_role(params[:role][:authorizable_name].to_s, authorizable_object)
        @users_roles = @user.study_and_project_roles.sort_by(&:name)

        flash[:error] = "Role was removed"
        render :partial => "roles", :status => 200
      else
        @users_roles = @user.study_and_project_roles.sort_by(&:name)
        flash[:error] = "A problem occurred while removing the role"
        render :partial => "roles", :status => 500
      end
    else
      @users_roles = @user.study_and_project_roles.sort_by(&:name)
      flash[:error] = "A problem occurred while removing the role"
      render :partial => "roles", :status => 401
    end
  end

  def filter
    if params[:q]
      @users = User.all(:order => "login ASC" ).select{ |p| p.name.downcase.include?(params[:q].downcase) || p.login.downcase.include?(params[:q].downcase) }
    end

    render :partial => "users", :locals => {:users => @users}
  end

  private
  def setup_user
    @user = User.find(params[:id], :include => [:roles])
  end

end
