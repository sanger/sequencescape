# frozen_string_literal: true

# Run on boot, but do not run again on reload
Rails.application.config.after_initialize do
  JSONAPI.configure do |config|
    # built in paginators are :none, :offset, :paged
    config.default_paginator = :paged
    config.default_page_size = 100
    config.maximum_page_size = 500

    # :underscored_key, :camelized_key, :dasherized_key, or custom
    config.json_key_format = :underscored_key
    config.route_format = :underscored_route
  end

  # Monkey patch the ApiKeyAuthenticatable concern into all JSONAPI::ResourceControllers
  JSONAPI::ResourceController.include(Api::V2::Concerns::ApiKeyAuthenticatable)
  JSONAPI::ResourceController.include(Api::V2::Concerns::DisableCsrfTokenAuthentication)
  JSONAPI::ResourceController.include(Api::V2::Concerns::DisableDestroyAction)

  # TODO: This is a temporary fix to allow the use of 422 Unprocessable Entity status code
  # in JSONAPI::Resources. This should be removed once the issue is resolved in the
  # JSONAPI::Resources gem.
  # See: https://github.com/cerebris/jsonapi-resources/issues/1456
  Rack::Utils::SYMBOL_TO_STATUS_CODE[:unprocessable_entity] = 422
end
