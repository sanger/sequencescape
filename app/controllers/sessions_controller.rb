#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2007-2011,2013 Genome Research Ltd.
class SessionsController < ApplicationController
  include Informatics::Globals

  skip_before_filter :login_required

  def index
    redirect_to :action => :login
  end

  def settings
  end

  def login
    return unless request.post?
    self.current_user = User.authenticate(params[:login], params[:password])
    if logged_in?
      flash[:notice] = "Logged in successfully"
      redirect_back_or_default(:controller => :studies)
    else
      if params
        flash[:notice] = "Your log in details don't match our records. Please try again."
      end
    end
  end

  def logout
    self.current_user.forget_me if logged_in?
    cookies.delete :auth_token
    reset_session
    flash[:notice] = "You have been logged out."
    redirect_back_or_default(:controller => :studies)
  end

end
