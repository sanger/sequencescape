# frozen_string_literal: true
#
Rails.application.config.to_prepare do
  JSONAPI.configure do |config|
    # built in paginators are :none, :offset, :paged
    config.default_paginator = :paged
    config.default_page_size = 100
    config.maximum_page_size = 500

    #:underscored_key, :camelized_key, :dasherized_key, or custom
    config.json_key_format = :underscored_key
    config.route_format = :underscored_route
  end

  begin
    # Monkey patch the ApiKeyAuthenticatable concern into all JSONAPI::ResourceControllers
    JSONAPI::ResourceController.include(Api::V2::Concerns::ApiKeyAuthenticatable)
    JSONAPI::ResourceController.include(Api::V2::Concerns::DisableCsrfTokenAuthentication)
  rescue StandardError => e
    Rails.logger.error("Error patching ApiKeyAuthenticatable in JSONAPI::ResourceController: #{e.message}")
  end
end
