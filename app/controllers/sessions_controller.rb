class SessionsController < ApplicationController
  include Informatics::Globals

  skip_before_filter :login_required

  filter_parameter_logging :password

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
