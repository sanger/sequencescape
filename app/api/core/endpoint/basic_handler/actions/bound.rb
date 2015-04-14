#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2007-2011,2011 Genome Research Ltd.
module Core::Endpoint::BasicHandler::Actions::Bound
  def bind_action(name, options, &block)
    class_handler = Class.new(Handler).tap { |handler| self.class.const_set(options[:as].to_s.camelize, handler) }
    register_handler(options[:to], class_handler.new(self, name, options, &block))
  end

  def self.delegate_to_bound_handler(name, target = name)
    line = __LINE__ + 1
    class_eval(%Q{
      def bound_#{name}(name, *args, &block)
        _handler_for(name).#{target}(*args, &block)
      end
    })
  end

  delegate_to_bound_handler :action_guard
  delegate_to_bound_handler :action_does_not_require_an_io_class, :does_not_require_an_io_class
end
