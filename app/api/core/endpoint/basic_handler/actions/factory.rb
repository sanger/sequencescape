module Core::Endpoint::BasicHandler::Actions::Factory
  def factory(options, &block)
    class_handler = Class.new(Handler).tap { |handler| self.class.const_set(options[:to].to_s.camelize, handler) }
    register_handler(options[:to], class_handler.new(options, &block))
  end
end
