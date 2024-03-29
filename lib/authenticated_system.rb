# frozen_string_literal: true
module AuthenticatedSystem
  protected

  # Returns true or false if the user is logged in.
  # Preloads @current_user with the user model if they're logged in.
  def logged_in?
    current_user != :false
  end

  # Accesses the current user from the session.
  def current_user
    @current_user ||= (session[:user] && User.find_by(id: session[:user])) || :false
  end

  # Store the given user in the session.
  def current_user=(new_user)
    session[:user] = new_user.nil? || new_user.is_a?(Symbol) ? nil : new_user.id
    @current_user = new_user
  end

  # Check if the user is authorized.
  #
  # Override this method in your controllers if you want to restrict access
  # to only a few actions or if you want to check if the user
  # has the correct rights.
  #
  # Example:
  #
  #  # only allow nonbobs
  #  def authorize?
  #    current_user.login != "bob"
  #  end
  def authorized?
    true
  end

  # Filter method to enforce a login requirement.
  #
  # To require logins for all actions, use this in your controllers:
  #
  #   before_action :login_required
  #
  # To require logins for specific actions, use this in your controllers:
  #
  #   before_action :login_required, :only => [ :edit, :update ]
  #
  # To skip this in a subclassed controller:
  #
  #   skip_before_action :login_required
  #
  # rubocop:todo Metrics/PerceivedComplexity, Metrics/MethodLength, Metrics/AbcSize
  def login_required # rubocop:todo Metrics/CyclomaticComplexity
    username, passwd = get_auth_data

    if username && passwd
      user = User.authenticate(username, passwd)
      self.current_user = user.nil? ? :false : user
    elsif params[:api_key]
      user = User.find_by(api_key: params[:api_key])
      self.current_user = user.nil? ? :false : user
    end

    respond_to do |accepts|
      accepts.html { logged_in? && authorized? ? true : access_denied }
      accepts.csv { logged_in? && authorized? ? true : access_denied }
      if configatron.disable_api_authentication == true
        accepts.xml { true }
        accepts.json { true }
      else
        accepts.xml { logged_in? && authorized? ? true : access_denied }
        accepts.json { logged_in? && authorized? ? true : access_denied }
      end
    end
  end

  # rubocop:enable Metrics/AbcSize, Metrics/MethodLength, Metrics/PerceivedComplexity

  def setup_current_user
    username, passwd = get_auth_data
    self.current_user ||= User.authenticate(username, passwd) || :false if username && passwd
  end

  # Redirect as appropriate when an access request fails.
  #
  # The default action is to redirect to the login screen.
  #
  # Override this method in your controllers if you want to have special
  # behavior in case the user is not authorized
  # to access the requested action.  For example, a popup window might
  # simply close itself.
  def access_denied
    respond_to do |accepts|
      accepts.html do
        store_location
        redirect_to controller: '/sessions', action: 'login'
      end
      accepts.xml { render xml: { error: "Couldn't authenticate you" }, status: :unauthorized }
      accepts.json { render json: { error: "Couldn't authenticate you" }, status: :unauthorized }
    end
    false
  end

  # Store the URI of the current request in the session.
  #
  # We can return to this location by calling #redirect_back_or_default.
  def store_location
    session[:return_to] = request.original_url
  end

  # Redirect to the URI stored by the most recent store_location call or
  # to the passed default.
  def redirect_back_or_default(default)
    redirect_to(session[:return_to] || default)
    session[:return_to] = nil
  end

  # Inclusion hook to make #current_user and #logged_in?
  # available as ActionView helper methods.
  def self.included(base)
    base.send :helper_method, :current_user, :logged_in?
  end

  # When called with before_action :login_from_cookie will check for an :auth_token
  # cookie and log the user back in if apropriate
  def login_from_cookie # rubocop:todo Metrics/AbcSize
    return unless cookies[:auth_token] && !logged_in?

    user = User.find_by(remember_token: cookies[:auth_token])
    if user && user.remember_token?
      user.remember_me
      self.current_user = user
      cookies[:auth_token] = {
        value: self.current_user.remember_token,
        expires: self.current_user.remember_token_expires_at
      }
      flash[:notice] = 'Logged in successfully'
    end
  end

  private

  @@http_auth_headers = %w[X-HTTP_AUTHORIZATION HTTP_AUTHORIZATION Authorization]

  # gets BASIC auth info
  def get_auth_data
    auth_key = @@http_auth_headers.detect { |h| request.env.has_key?(h) }
    auth_data = request.env[auth_key].to_s.split if auth_key.present?
    auth_data && auth_data[0] == 'Basic' ? Base64.decode64(auth_data[1]).split(':')[0..1] : [nil, nil]
  end
end
