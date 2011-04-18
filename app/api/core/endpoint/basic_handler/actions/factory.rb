module Core::Endpoint::BasicHandler::Actions::Factory
  def factory(options, &block)
    register_handler(options[:to], Class.new(Handler).new(options, &block))
  end
end
