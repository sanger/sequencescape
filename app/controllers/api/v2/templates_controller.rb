# frozen_string_literal: true

module Api
  module V2
    # This stub class is here to appease a problem with JSONAPI v0.9
    # and polymorphic relationships. Also stubbing the TemplateResource.
    class TemplatesController < JSONAPI::ResourceController
      include Api::V2::ApiKeyAuthenticatable
    end
  end
end
