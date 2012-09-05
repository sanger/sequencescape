module User::Authentication
  def self.included(base)
    base.class_eval do
      extend ClassMethods
      extend Ldap
      extend SangerSingleSignOn
      extend Local
    end
  end

  def authenticated?(password)
    crypted_password == encrypt(password)
  end

  def update_profile_via_ldap
    ldap = Net::LDAP.new(:host => configatron.ldap_server, :port => configatron.ldap_port)

    filter = Net::LDAP::Filter.eq( "uid", self.login )
    treebase = "ou=people,dc=sanger,dc=ac,dc=uk"

    ldap_profile = ldap.search( :base => treebase, :filter => filter )[0]
    # If we have two or more records, something is off with LDAP

    {:email => "mail", :first_name => "givenname", :last_name => "sn"}.each do |attr,ldap_attr|
      self[attr] = ldap_profile[ldap_attr][0] if self[attr].blank?
    end
    self.save if self.changed?

  rescue Exception => e
    logger.error "Profile failed for user #{login}: result code #{ldap.get_operation_result.code} message #{ldap.get_operation_result.message} - #{e}"
  end
  private :update_profile_via_ldap

  module ClassMethods
    # Authenticates a user by their login name and unencrypted password.  Returns the user or nil.
    def authenticate(login, password)
      if configatron.authentication == "ldap"
        authenticated = authenticate_with_ldap(login, password)
      else
        authenticated = authenticate_by_local(login, password)
      end
      if authenticated
        u = find_or_create_by_login(login)
        if u.nil?
          logger.error "Failed to find or create user #{login}"
        else
          u.send(:update_profile_via_ldap) unless u.profile_complete?
        end
        u
      else
        nil
      end
    end
  end

  module Ldap
    def authenticate_with_ldap(login, password)
      # TODO - Extract LDAP specifics to configuration
      username = "uid=" << login << ",ou=people,dc=sanger,dc=ac,dc=uk"
      ldap = Net::LDAP.new(
          :host => configatron.ldap_server,
          :port => configatron.ldap_secure_port,
          :encryption => :simple_tls,
          :auth => {
            :method => :simple,
            :username => username,
            :password => password
          }
      )
      begin
        ldap.bind
      rescue Exception => e
        raise e, "LDAP connection problem: #{e}", caller
      end
      password = "" # clear out in case of crashes
      if ldap.bind
        logger.info "Authentication succeeded"
        true
      else
        logger.warn "Authentication failed for user #{login}: result code #{ldap.get_operation_result.code} message #{ldap.get_operation_result.message}"
        false
      end
    end
  end

  module SangerSingleSignOn
    def self.extended(base)
      base.named_scope :with_fresh_cookie, lambda { |c| { :conditions => [ 'cookie=? AND cookie_validated_at > ?', c, configatron.sanger_auth_freshness.minutes.ago ] } }
    end

    if Rails.env == 'development'
      def authenticate_by_sanger_cookie(cookie_value)
        self.find_by_login(cookie_value)
      end
    else
      def authenticate_by_sanger_cookie(cookie_value)
        self.with_fresh_cookie(cookie_value).first || validate_user_with_single_sign_on_service(cookie_value)
      end
    end

    def validate_user_with_single_sign_on_service(cookie_value)
      user_from_single_sign_on_service(cookie_value).tap do |user|
        user.update_attributes!(:cookie => cookie_value, :cookie_validated_at => Time.now) unless user.nil?
      end
    end
    private :validate_user_with_single_sign_on_service

    def init_curl(uri)
      curl = Curl::Easy.new(URI.parse(uri).to_s)
      if configatron.disable_web_proxy == true
        curl.proxy_url = ''
      elsif not configatron.proxy.blank?
        curl.headers["User-Agent"] = "Sequencescape"
        curl.proxy_url = configatron.proxy
        curl.proxy_tunnel = true
      end
      curl
    end
    private :init_curl

    def get_sanger_token(username,password)
      begin
        curl = self.init_curl(configatron.sanger_login_service)
        wtsi_token =""
        curl.on_header do |header|
          wtsi_token = "#{$1}" if header =~ /^Set-Cookie: WTSISignOn=([^; ]+);/
          header.length
        end
        curl.http_post(configatron.sanger_login_service,Curl::PostField.content('credential_0', username), Curl::PostField.content('credential_1', password),Curl::PostField.content('destination', '/'))
        wtsi_token
      rescue
        logger.info "Authentication service down #{configatron.sanger_login_service} user: #{username}: #{$!}"
        return nil
      end
    end

    def user_from_single_sign_on_service(value)
      logger.debug "Authentication by cookie: " + value
      res = ""
      begin
        curl = init_curl(configatron.sanger_auth_service)
        curl.http_post(Curl::PostField.content('cookie',value))
        res = curl.body_str
      rescue SocketError
        logger.info "Authentication service down #{configatron.sanger_auth_service} cookie: #{value}"
      rescue Curl::Err::RecvError
        logger.info "Authentication service down #{configatron.sanger_auth_service} cookie: #{value}"
      end

      u = nil
      begin
        result = ActiveSupport::JSON.decode(res)
        logger.debug "Authentication by cookie: " + res

        if result && result["valid"] == 1 && result["username"]
          u = find_or_create_by_login(result["username"])
        end
      rescue ParseError
        logger.info "Authentication service parse error #{configatron.sanger_auth_service} cookie: #{value}"
        return nil
      end
      u
    end
    private :user_from_single_sign_on_service
  end

  module Local
    def authenticate_by_local(login, password)
      u = find_by_login(login) # need to get the salt
      u && u.authenticated?(password) ? u : nil
    end
  end
end
