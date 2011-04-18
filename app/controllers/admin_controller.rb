class AdminController < ApplicationController

  before_filter :admin_login_required

  def index
    @studies = Study.count
    @users = User.count
    @samples = Sample.count
    @items = Item.count
    @requests = Request.count
  end
  
  def filter
    if params[:q].blank?
      @users = User.all
    else
      @users = User.find_all_by_login(params[:q])
    end
    render :partial => 'admin/users/users', :locals => { :users => @users }
  end

end
