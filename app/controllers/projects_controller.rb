class ProjectsController < ApplicationController
  before_filter :login_required
  before_filter :set_variables_for_project, :only => [:show, :edit, :update, :destroy, :studies]
 #TODO: before_filter :redirect_if_not_owner_or_admin, :only => [:create, :update, :destroy, :edit, :new]

  def index
    @projects = Project.all(:order => 'name ASC').paginate(:page => params[:page])

    respond_to do |format|
      format.html
      format.xml  { render :xml => Project.all(:order => 'name ASC') }
      format.json  { render :json => Project.all(:order => 'name ASC') }
    end
  end

  def show
    if current_user != :false
      @workflow = current_user.workflow
      # TODO[xxx]: filtered the project based on user workflow
    end

    respond_to do |format|
      format.html
      format.xml
      format.json  { render :json => @project }
    end
  end

  def new
    @project = Project.new
    @project.new_quotas

    respond_to do |format|
      format.html
      format.xml   { render :xml  => @project }
      format.json  { render :json => @project }
    end
  end

  def edit
    @project = Project.find(params[:id])
    @users   = User.all
    @project.new_quotas
  end

  def create
    # TODO[5002667]: All of this code should be in a before_create/after_create callback in the Project model ...
    quota_params = []
    if params["project"]["quotas"]
      quota_params = params["project"].delete("quotas")
    end
    @project = Project.new(params[:project])
    @project.save!

    current_user.has_role('manager', @project)

    # Creates an event when a new Project is created
    EventFactory.new_project(@project, current_user)

    unless quota_params.empty?
      @project.add_quotas(quota_params)
    end
    # TODO[5002667]: ... to here.

    flash[:notice] = "Your project has been created"
    respond_to do |format|
      format.html { redirect_to project_path(@project) }
      format.xml  { render :xml  => @project, :status => :created, :location => @project }
      format.json { render :json => @project, :status => :created, :location => @project }
    end
  rescue ActiveRecord::RecordInvalid => exception
    action_flash[:error] = "Problems creating your new project"
    respond_to do |format|
      format.html {
        @project.new_quotas=(quota_params)
        render :action => "new"
      }
      format.xml  { render :xml  => @project.errors, :status => :unprocessable_entity }
      format.json { render :json => @project.errors, :status => :unprocessable_entity }
    end
  end

  def update

    quota_params = []
    if params["project"]["quotas"]
      quota_params = params["project"].delete("quotas")
    end
    respond_to do |format|
      if @project.update_attributes(params[:project])
        flash[:notice] = 'Project was successfully updated.'
        format.html { redirect_to(@project) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @project.errors, :status => :unprocessable_entity }
      end
    end
  end

  def destroy
    @project.destroy

    respond_to do |format|
      format.html { redirect_to(projects_url) }
      format.xml  { head :ok }
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
    @project    = Project.find(params[:id])
    #@all_roles  = Role.all(:select => " distinct `name`")
    @all_roles  = Role.all(:conditions => {:name => ["owner","follower","manager"]},:select => " distinct `name`")
    @roles      = Role.find(:all, :conditions => {:authorizable_id => @project.id, :authorizable_type => "Project"})
    @users      = User.all(:order => :first_name)
  end

  def follow
    @project    = Project.find(params[:id])
    if current_user.has_role? 'follower', @project
      current_user.has_no_role 'follower', @project
      flash[:notice] = "You have stopped following the '#{@project.name}' project."
    else
      current_user.has_role 'follower', @project
      flash[:notice] = "You are now following the '#{@project.name}' project."
    end
    redirect_to project_path(@project)
  end

  def grant_role
    @user    = User.find(params[:role][:user])
    @project = Project.find(params[:id])
    @role    = Role.find_by_name(params[:role][:authorizable_type])

    if request.xhr?
      if params[:role]
        @user.has_role(params[:role][:authorizable_type].to_s, @project)
        @roles   = Role.find(:all, :conditions => {:authorizable_id => @project.id, :authorizable_type => "Project"})
        flash[:notice] = "Role added"
        render :partial => "roles", :status => 200
      else
        @roles   = Role.find(:all, :conditions => {:authorizable_id => @project.id, :authorizable_type => "Project"})
        flash[:error] = "A problem occurred while adding the role"
        render :partial => "roles", :status => 500
      end
    else
      @roles   = Role.find(:all, :conditions => {:authorizable_id => @project.id, :authorizable_type => "Project"})
      flash[:error] = "A problem occurred while adding the role"
      render :partial => "roles", :status => 401
    end
  end

  def remove_role
    @user    = User.find(params[:role][:user])
    @project = Project.find(params[:id])
    @role    = Role.find_by_name(params[:role][:authorizable_type])

    if request.xhr?
      if params[:role]
        @user.has_no_role(params[:role][:authorizable_type].to_s, @project)
        @roles   = Role.find(:all, :conditions => {:authorizable_id => @project.id, :authorizable_type => "Project"})
        flash[:error] = "Role was removed"
        render :partial => "roles", :status => 200
      else
        @roles   = Role.find(:all, :conditions => {:authorizable_id => @project.id, :authorizable_type => "Project"})
        flash[:error] = "A problem occurred while removing the role"
        render :partial => "roles", :status => 500
      end
    else
      @roles   = Role.find(:all, :conditions => {:authorizable_id => @project.id, :authorizable_type => "Project"})
      flash[:error] = "A problem occurred while removing the role"
      render :partial => "roles", :status => 401
    end
  end

  private
  def set_variables_for_project
    @project = Project.find(params[:id])
  end
end
