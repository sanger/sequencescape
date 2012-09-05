class UsersController < ApplicationController

  def index
    @users = User.all
  end

  def show
    if current_user.administrator? || current_user.id == params[:id].to_i
      @user = User.find(params[:id])
    else
      flash[:error] = "You don't have permission to view that profile: here is yours instead."
      redirect_to :action => :show, :id => current_user.id
    end
  end

  def edit
    if current_user.administrator? || current_user.id == params[:id].to_i
      @user = User.find(params[:id])
    else
      flash[:error] = "You don't have permission to edit that profile: here is yours instead."
      redirect_to :action => :show, :id => current_user.id
    end
  end

  def update
    @user = User.find(params[:id])
    if @user.id == params[:id].to_i
      @user.update_attributes(params[:user])
    end
    if @user.save
      flash[:notice] = "Profile updated"
    else
      flash[:error] = "Problem updating profile."
    end
    redirect_to :action => :show, :id => @user.id
  end

  def projects
    @user = User.find(params[:id])
    @projects = @user.projects.paginate :page => params[:page]
  end

  def study_reports
    @user = User.find(params[:id])
    @study_reports = StudyReport.without_files.for_user(@user).paginate(:page => params[:page], :order => "id desc")
  end

end
