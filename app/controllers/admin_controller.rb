class AdminController < ApplicationController
  before_action :admin_login_required

  def index
  end

  def filter
    @users = if params[:q].blank?
               User.all
             else
               User.where(login: params[:q])
             end
    render partial: 'admin/users/users', locals: { users: @users }
  end
end
