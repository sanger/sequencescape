# frozen_string_literal: true
module Core::Endpoint::BasicHandler::Associations::HasMany
  #
  # Defines a has_many relationship which will be exposed via the v1 api
  # @param name [Symbol] The name of the association to expose via the api
  # @param options [Hash] Option parameters for the association
  # @option options [String] :to Used to generate the url eg to: 'wells' results in resource_uuid/wells
  # @option options [String] :json The key to identify the association in the json
  # @option options [String] :scoped Scopes to apply to the association, separated by a '.'
  # @option options [Integer] :per_page The number of resources per page when accessed via the association <optional>
  # @option options [Array,Hash] :include Include options on the association
  # @yield [] Use block to define additional actions on the association.
  #
  # @return [Void]
  def has_many(name, options, &)
    class_handler = Class.new(Handler).tap { |handler| self.class.const_set(name.to_s.camelize, handler) }
    register_handler(options[:to], class_handler.new(name, options, &))
  end
end
