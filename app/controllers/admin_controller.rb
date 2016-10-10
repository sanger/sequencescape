# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2012,2015 Genome Research Ltd.

class AdminController < ApplicationController

  before_action :admin_login_required

  def index
  end

  def filter
    if params[:q].blank?
      @users = User.all
    else
      @users = User.where(login:params[:q])
    end
    render partial: 'admin/users/users', locals: { users: @users }
  end

end
