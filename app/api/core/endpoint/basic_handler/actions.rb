#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2007-2011,2011,2012,2013 Genome Research Ltd.
module Core::Endpoint::BasicHandler::Actions
  class UnsupportedAction < StandardError
    def initialize(action, request)
      super(action.to_s)
    end
  end

  def self.included(base)
    base.class_eval do
      include Core::Endpoint::BasicHandler::Actions::Bound
      include Core::Endpoint::BasicHandler::Actions::Factory
      include Core::Endpoint::BasicHandler::Actions::Guards
      include Core::Endpoint::BasicHandler::EndpointLookup
      include Core::Abilities::ActionBehaviour
    end
  end

  ACTIONS_WITH_SUCCESS_CODES = {
    :create => 201,
    :read   => 200,
    :update => 200,
    :delete => 200,

    :create_from_file => 201,
    :update_from_file => 200
  }

  ACTIONS_WITH_SUCCESS_CODES.each do |action, status_code|
    line = __LINE__ + 1
    class_eval(%Q{
      def #{action}(request, path, &block)
        current, *rest = path
        handler = handler_for(current)
        return handler.#{action}(request, rest, &block) unless self == handler

        check_request_io_class!(request)
        check_authorisation!(self, #{action.inspect}, request, request.target)
        request.response do |response|
          response.status(#{status_code})
          _#{action}(request, response) do |handler, object|
            response.handled_by ||= handler
            response.object     = object
          end
        end
      end

      def _#{action}(request, response)
        raise ::Core::Service::UnsupportedAction
      end
    }, __FILE__, line)
  end

  def check_request_io_class!(request)
    raise StandardError, "Need an I/O class for this request" if request.io.nil?
  end

  def does_not_require_an_io_class
    self.singleton_class.class_eval(%Q{def check_request_io_class!(_) ; end}, __FILE__, __LINE__)
  end

  def disable(*actions)
    actions.each do |action|
      line = __LINE__ + 1
      singleton_class.class_eval(%Q{
        def _#{action}(request, response)
          raise ::Core::Service::UnsupportedAction
        end
      }, __FILE__, line)
      @actions.delete(action.to_sym)
    end
  end

  def action(name, options = {}, &block)
    declare_action(name, options, &block)
    attach_action(options[:as] || name, name)
    action_guard(name, options[:if]) if options.key?(:if)
  end

  def declare_action(name, options, &block)
    action_implementation_method =
      case
      when block_given?
        singleton_class.class_eval { define_method(:"_#{name}_internal", &block) }
        :"_#{name}_internal"

      when options[:to] then options[:to]
      else raise StandardError, "Block or :to option needed to declare action"
      end

    line = __LINE__ + 1
    singleton_class.class_eval(%Q{
      def _#{name}(request, response)
        object = #{action_implementation_method}(request, response)
        yield(endpoint_for_object(object).instance_handler, object)
      end
    }, __FILE__, line)
  end
  private :declare_action

  def generate_json_actions(object, options)
    options[:stream].block('actions') do |result|
      actions(object, options).each do |name, url|
        result.attribute(name, url)
      end
    end
  end
end
