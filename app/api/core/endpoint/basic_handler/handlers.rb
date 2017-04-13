# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2012,2015 Genome Research Ltd.

module Core::Endpoint::BasicHandler::Handlers
  # Handler that behaves like it never deals with any URLs
  NullHandler = Object.new.tap do |handler|
    [:create, :read, :update, :delete].each do |action|
      handler.define_singleton_method(action) do |*_args|
        raise ::Core::Service::UnsupportedAction
      end
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
    @handlers.select do |_name, handler|
      handler.is_a?(Core::Endpoint::BasicHandler::Actions::InnerAction)
    end.map do |_name, handler|
      handler.send(:actions, object, options)
    end.inject(super) do |actions, subactions|
      actions.merge(subactions)
    end
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
