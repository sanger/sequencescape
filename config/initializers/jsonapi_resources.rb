# frozen_string_literal: true
JSONAPI.configure do |config|
  # built in paginators are :none, :offset, :paged
  config.default_paginator = :paged
  config.default_page_size = 100
  config.maximum_page_size = 500

  #:underscored_key, :camelized_key, :dasherized_key, or custom
  config.json_key_format = :underscored_key
  config.route_format = :underscored_route
end

# Monkey patch the ApiKeyAuthenticatable concern into all JSONAPI::ResourceControllers
class JSONAPI::ResourceController
  include Api::V2::Concerns::ApiKeyAuthenticatable
end

# Monkey patch the DefaultIncludesParser concern into JSONAPI::RequestParser .
# TODO: Explain what we are doing here and why using 'prepend' is important.
class JSONAPI::RequestParser
  prepend Api::V2::Concerns::DefaultIncludesParser
end

class JSONAPI::ResourceSerializer
  prepend Api::V2::Concerns::IncludeOptionalLinkage
end
