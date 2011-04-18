module Core::Endpoint::BasicHandler::Associations::HasMany
  def has_many(name, options, &block)
    register_handler(options[:to], Class.new(Handler).new(name, options, &block))
  end
end
