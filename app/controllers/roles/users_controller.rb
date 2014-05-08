class Roles::UsersController < ApplicationController

  def index
    @role   = Role.find(params[:role_id], :include => [:users])
    @users  = User.all.select{|user| user.has_role? @role.name}
    @users  = @users.sort_by{|n| n.login}
  end
end
