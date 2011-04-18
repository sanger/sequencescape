module Core::Service::Authentication
  class UnauthenticatedError < Core::Service::Error
    def self.no_cookie!
      raise self, 'no WTSISignOn cookie provided'
    end

    def self.unauthenticated!
      raise self, 'the WTSISignOn cookie is invalid'
    end

    def api_error(response)
      response.general_error(401)
    end
  end

  module Helpers
    def user
      @user
    end
  end

  def self.registered(app)
    app.helpers Helpers

    app.before_all_actions do
      single_sign_on_cookie = request.cookies['WTSISignOn']
      UnauthenticatedError.no_cookie! if single_sign_on_cookie.blank?
      @user = User.authenticate_by_sanger_cookie(single_sign_on_cookie) or User.find_by_api_key(single_sign_on_cookie) or UnauthenticatedError.unauthenticated!
    end
  end
end
