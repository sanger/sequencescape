# frozen_string_literal: true

module Api
  module V2
    # This stub class is here to appease a problem with JSONAPI v0.9
    # and polymorphic relationships. Also stubbing the TemplateResource.
    class TemplatesController < JSONAPI::ResourceController
      # By default JSONAPI::ResourceController provides most the standard
      # behaviour, and in many cases this file may be left empty.
    end
  end
end
