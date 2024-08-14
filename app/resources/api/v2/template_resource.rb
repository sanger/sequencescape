# frozen_string_literal: true

module Api
  module V2
    # @abstract
    #
    # This stub class is here to appease a problem with JSONAPI v0.9
    # and polymorphic relationships. Also stubbing the TemplatesController.
    class TemplateResource < BaseResource
      abstract
    end
  end
end
