# frozen_string_literal: true
module Core::Service::Authentication # rubocop:todo Style/Documentation
  class UnauthenticatedError < Core::Service::Error # rubocop:todo Style/Documentation
    def self.no_cookie!
      raise self, 'no authentication provided'
    end

    def self.unauthenticated!
      raise self, 'could not be authenticated'
    end

    def api_error(response)
      response.general_error(401)
    end
  end

  module Helpers # rubocop:todo Style/Documentation
    def user
      @user
    end
  end

  def self.registered(app)
    app.helpers Helpers
  end
end
