# frozen_string_literal: true
class AdminController < ApplicationController
  authorize_resource :sequencescape, parent: true, parent_action: :administer

  def index
  end

  def filter
    @users = params[:q].blank? ? User.all : User.where(login: params[:q])
    render partial: 'admin/users/users', locals: { users: @users }
  end
end
