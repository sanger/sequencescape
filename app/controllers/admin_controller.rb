class AdminController < ApplicationController # rubocop:todo Style/Documentation
  authorize_resource :sequencescape, parent: true, parent_action: :administer

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
