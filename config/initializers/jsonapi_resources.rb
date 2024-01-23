# frozen_string_literal: true
JSONAPI.configure do |config|
  # built in paginators are :none, :offset, :paged
  config.default_paginator = :paged
  config.default_page_size = 100
  config.maximum_page_size = 500
  config.always_include_to_one_linkage_data = true
  config.always_include_to_many_linkage_data = true

  #:underscored_key, :camelized_key, :dasherized_key, or custom
  config.json_key_format = :underscored_key
  config.route_format = :underscored_route
end

# Monkey patch the ApiKeyAuthenticatable concern into all JSONAPI::ResourceControllers
class JSONAPI::ResourceController
  include Api::V2::Concerns::ApiKeyAuthenticatable
end
