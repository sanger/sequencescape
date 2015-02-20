#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2007-2011,2012 Genome Research Ltd.
class Roles::UsersController < ApplicationController

  def index
    @role   = Role.find(params[:role_id], :include => [:users])
    @users  = User.all.select{|user| user.has_role? @role.name}
    @users  = @users.sort_by{|n| n.login}
  end
end
