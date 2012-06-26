class Admin::ProjectsController < ApplicationController
  before_filter :admin_login_required

  def index
    @projects = Project.all(:order => "name ASC")
    @request_types = RequestType.all(:order => "name ASC")
  end

  def show
    @project = Project.find(params[:id])

    # Filter the RequestTypes to hide Controls
    @request_types = RequestType.all(
      :order => 'name ASC',
      :conditions  => ['request_class_name != ?', 'ControlRequest']
    )

    unless @project.quotas.empty?
      @project.quotas.each do |p|
        @request_types.delete_if{|t| t.id == p.request_type_id}
      end
    end
  end

  def update
   @project = Project.find(params[:id])
   flash[:notice] = "Your project has been updated"
   render :partial => "manage_single_project"
  end

  def editor
    @request_types = RequestType.all(:order => "name ASC")
    if params[:id] != "0"
      @project = Project.find(params[:id])
      render :partial => "editor", :locals => { :project => @project }
    else
      render :nothing => true
    end
  end

  def filter
    unless params[:filter].nil?
      if params[:filter][:by] == "not approved"
        filter_conditions = {:approved => false}
      end
    end

    if params[:filter][:by] == "not approved" || params[:filter][:by] == "all"
      @projects = Project.find(:all, :conditions => filter_conditions, :order => :name ).select { |p| p.name.include? params[:q] }
    end

    unless params[:filter].nil?
      if params[:filter][:by] == "unallocated division"
        @projects = Project.with_unallocated_budget_division.all(:conditions => [ 'name LIKE ?', "%#{params[:q]}%" ])
      elsif params[:filter][:by] == "unallocated manager"
        @projects = Project.all.select { |p| p.name.include?(params[:q]) && !(p.roles.map { |r| r.name }.include?('manager')) }
      end
    end

    case params[:filter][:status]
    when "open"
      @projects = @projects.select { |p| p.active? }
    when "closed"
      @projects = @projects.reject { |p| p.active? }
    end
     @request_types = RequestType.all.sort_by{|r| r.name}
    render :partial => "filtered_projects"
  end

  def managed_update
    @project = Project.find(params[:id])
    redirect_if_not_owner_or_admin(@project)
    @request_types = RequestType.all(:order => "name ASC")
    # Cleans submitted quotas. Does not accept 0 quotas

    quota_updates = {}
    if params[:quota]
      quota_updates = params[:quota].delete_if{|g,k| k == "0"}
    end
    params.delete(:quota)

    existing_quota_changes = params[:project].delete(:quotas)||{}
    quota_updates.merge!(existing_quota_changes)

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

      unless @project.compare_quotas( quota_updates )
        @project.add_quotas(quota_updates)
        EventFactory.quota_updated(@project, current_user)
      end

      flash[:notice] = "Your project has been updated"
      redirect_to :controller => "admin/projects", :action => "update", :id => @project.id
    else
      logger.warn "Failed to update attributes: #{@project.errors.map {|e| e.to_s }}"
      flash[:error] = "Failed to update attributes for project!"
      render :action => :show, :id => @project.id and return
    end
  end

  def sort
    @projects = Project.find(:all).sort_by { |project| project.name }
    if params[:sort] == "date"
      @projects = @projects.sort_by { |project| project.created_at}
    elsif params[:sort] == "owner"
      @projects = @projects.sort_by { |project| project.user_id }
    end
    render :partial => "projects"
  end

  def reset_quota
    Quota.delete_all("request_type_id = #{params[:request_type]} AND project_id = #{params[:id]}")
    flash[:notice] = "Project's quota was updated"
    redirect_to :action => "update", :id => params[:id]
  end

  private

  def redirect_if_not_owner_or_admin(project)
    unless current_user.owner?(project) or current_user.is_administrator?
      flash[:error] = "Project details can only be altered by the owner (#{project.user.login}) or an administrator"
      redirect_to project_path(project)
    end
  end
end
