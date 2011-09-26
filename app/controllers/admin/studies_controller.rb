class Admin::StudiesController < ApplicationController
  before_filter :admin_login_required

  def index
    @studies = Study.all(:order => "name ASC")
  end

  def show
    @study = Study.find(params[:id])
  end

  def update
   @study = Study.find(params[:id])
   flash[:notice] = "Your study has been updated"
   render :partial => "manage_single_study"
  end

  def editor
    @request_types = RequestType.all(:order => "name ASC")
    if params[:id] != "0"
      @study = Study.find(params[:id])
      render :partial => "editor", :locals => { :study => @study }
    else
      render :nothing => true
    end
  end

  # TODO: remove unneeded code
  def filter
    unless params[:filter].nil?
      if params[:filter][:by] == "not approved"
        filter_conditions = {:approved => false}
      end
    end

    if params[:filter][:by] == "not approved" || params[:filter][:by] == "all"
      @studies = Study.find(:all, :conditions => filter_conditions, :order => :name ).select { |p| p.name.include? params[:q] }
    end

    unless params[:filter].nil?
      if params[:filter][:by] == "unallocated manager"
        @studies = Study.all.select { |p| p.name.include?(params[:q]) && !(p.roles.map { |r| r.name }.include?('manager')) }
      end
    end

    case params[:filter][:status]
    when "open"
      @studies = @studies.select { |p| p.active? }
    when "closed"
      @studies = @studies.reject { |p| p.active? }
    end
    @request_types = RequestType.all.sort_by{|r| r.name}
    render :partial => "filtered_studies"
  end


  def managed_update
    @study = Study.find(params[:id])
    redirect_if_not_owner_or_admin(@study)

    Document.create!(:documentable => @study, :uploaded_data => params[:study][:uploaded_data]) unless params[:study][:uploaded_data].blank?
    params[:study].delete(:uploaded_data)

    ActiveRecord::Base.transaction do
      @study.update_attributes!(params[:study])
      flash[:notice] = "Your study has been updated"
      redirect_to :controller => "admin/studies", :action => "update", :id => @study.id
    end
  rescue ActiveRecord::RecordInvalid => exception
    logger.warn "Failed to update attributes: #{@study.errors.map {|e| e.to_s }}"
    flash[:error] = "Failed to update attributes for study!"
    render :action => :show, :id => @study.id and return
  end

  def sort
    @studies = Study.find(:all).sort_by { |study| study.name }
    if params[:sort] == "date"
      @studies = @studies.sort_by { |study| study.created_at}
    elsif params[:sort] == "owner"
      @studies = @studies.sort_by { |study| study.user_id }
    end
    render :partial => "studies"
  end

  private

  def redirect_if_not_owner_or_admin(study)
    unless current_user.owner?(study) or current_user.is_administrator?
      flash[:error] = "Study details can only be altered by the owner (#{study.user.login}) or an administrator"
      redirect_to study_path(study)
    end
  end
end
