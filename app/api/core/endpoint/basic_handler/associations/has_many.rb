module Core::Endpoint::BasicHandler::Associations::HasMany
  def has_many(name, options, &block)
    class_handler = Class.new(Handler).tap { |handler| self.class.const_set(name.to_s.camelize, handler) }
    register_handler(options[:to], class_handler.new(name, options, &block))
  end
end
