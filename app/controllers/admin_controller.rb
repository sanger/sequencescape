class AdminController < ApplicationController
  before_action :admin_login_required

  def index
  end

  def filter
    if params[:q].blank?
      @users = User.all
    else
      @users = User.where(login: params[:q])
    end
    render partial: 'admin/users/users', locals: { users: @users }
  end
end
