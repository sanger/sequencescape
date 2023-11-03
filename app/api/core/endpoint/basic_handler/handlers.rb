# frozen_string_literal: true
module Core::Endpoint::BasicHandler::Handlers
  # Handler that behaves like it never deals with any URLs
  NullHandler =
    Object.new.tap do |handler|
      %i[create read update delete].each do |action|
        handler.define_singleton_method(action) { |*_args| raise ::Core::Service::UnsupportedAction }
      end
    end

  def initialize
    super
    @handlers = {}
  end

  def related
    @handlers.map(&:last)
  end

  def actions(object, options)
    @handlers
      .select { |_name, handler| handler.is_a?(Core::Endpoint::BasicHandler::Actions::InnerAction) }
      .map { |_name, handler| handler.send(:actions, object, options) }
      .inject(super) { |actions, subactions| actions.merge(subactions) }
  end

  def register_handler(segment, handler)
    @handlers[segment.to_sym] = handler
  end
  private :register_handler

  def handler_for(segment)
    return self if segment.nil?

    _handler_for(segment) || NullHandler
  end
  private :handler_for

  def _handler_for(segment)
    @handlers[segment.to_sym]
  end
  private :_handler_for
end
