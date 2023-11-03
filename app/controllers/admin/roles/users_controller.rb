# frozen_string_literal: true
class Admin::Roles::UsersController < ApplicationController
  def index
    @role_name = params[:role_id]
    @users = User.joins(:roles).where(roles: { name: params[:role_id] }).order(:login).distinct
  end
end
