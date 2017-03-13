# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2012,2014,2015 Genome Research Ltd.

class UsersController < ApplicationController
  # WARNING! This filter bypasses security mechanisms in rails 4 and mimics rails 2 behviour.
  # It should be removed wherever possible and the correct Strong  Parameter options applied in its place.
  before_action :evil_parameter_hack!

  before_action :validate_user, except: [:index, :projects, :study_reports]
  before_action :find_user, except: [:index]

  def index
    @users = User.all
  end

  def show
  end

  def edit
  end

  def update
    params[:user].delete(:swipecard_code) if params[:user][:swipecard_code].blank?
    @user = User.find(params[:id])
    if @user.id == params[:id].to_i
      @user.update_attributes(params[:user])
    end
    if @user.save
      flash[:notice] = 'Profile updated'
    else
      flash[:error] = 'Problem updating profile.'
    end
    redirect_to action: :show, id: @user.id
  end

  def projects
    @projects = @user.projects.page(params[:page])
  end

  def study_reports
    @study_reports = StudyReport.for_user(@user).page(params[:page]).order(id: :desc)
  end

  private

  def validate_user
    if current_user.administrator? || current_user.id == params[:id].to_i
      true
    else
      flash[:error] = "You don't have permission to view or edit that profile: here is yours instead."
      redirect_to action: :show, id: current_user.id
    end
  end

  def find_user
    @user = User.find(params[:id])
  end
end
