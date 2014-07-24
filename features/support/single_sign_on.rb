require File.expand_path(File.join(File.dirname(__FILE__), 'fake_sinatra_service.rb'))

class FakeSingleSignOnService < FakeSinatraService
  def initialize(*args, &block)
    super
    configatron.sanger_auth_service = "http://#{host}:#{port}/cgi-bin/prodsoft/SSO/isAuth.pl"
    configatron.verify_login_url    = "http://#{host}:#{port}/cgi-bin/prodsoft/SSO/isAuth.pl"
  end

  def cookie_to_login_map
    @cookie_to_login_map ||= {}
  end

  def clear
    @cookie_to_login_map = {}
  end

  def map_cookie_to_login(cookie, login)
    self.cookie_to_login_map[cookie] = login
  end

  def unmap_cookie(cookie)
    self.cookie_to_login_map.delete(cookie)
  end

  def login_for_cookie(cookie)
    self.cookie_to_login_map[cookie]
  end

  def service
    Service
  end

  class Service < FakeSinatraService::Base
    post('/cgi-bin/prodsoft/SSO/isAuth.pl') do
      login = FakeSingleSignOnService.instance.login_for_cookie(params['cookie'])
      json  = login.blank? ? { 'valid' => 0 } : { 'valid' => 1, 'username' => login }
      headers('Content-Type' => 'application/json')
      body(json.to_json)
    end
  end
end

FakeSingleSignOnService.install_hooks(self, '@single-sign-on')
