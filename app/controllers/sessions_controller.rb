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
      # if params[:remember_me] == "1"
      #   self.current_user.remember_me
      #   cookies[:auth_token] = { :value => self.current_user.remember_token , :expires => self.current_user.remember_token_expires_at }
      # end
      flash[:notice] = "Logged in successfully"
      redirect_back_or_default(:controller => :studies)
    else
      if params
        flash[:notice] = "Your log in details don't match our records. Please try again."
      end
    end
  end

  def authenticate
    self.current_user = User.authenticate_by_api_key(params[:id])

    if logged_in?
      self.current_user.remember_me
      cookies[:auth_token] = { :value => self.current_user.remember_token , :expires => self.current_user.remember_token_expires_at }
      logger.info "AUTH: " + params[:id]
      logger.info "USER: " + current_user.login
    end

    if current_user.instance_of?(User)
      respond_to do |format|
        format.html # show.rhtml
        format.xml  { render :xml => current_user.to_xml }
        format.json  { render :json => current_user.to_json }
      end
    else
      respond_to do |format|
        format.html { render :text => "Login failed", :status => 406}
        format.xml  { render :xml => "<message>fail</message>", :status => 406 }
        format.json  { render :json => "fail".to_json, :status => 406 }
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
