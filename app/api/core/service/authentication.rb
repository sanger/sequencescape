#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2007-2011,2011,2013 Genome Research Ltd.
module Core::Service::Authentication
  class UnauthenticatedError < Core::Service::Error
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

  module Helpers
    def user
      @user
    end
  end

  def self.registered(app)
    app.helpers Helpers
  end
end
