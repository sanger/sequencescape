class ::Core::Io::Buffer
  def initialize(stream)
    @stream, @buffer = stream, StringIO.new
    return unless block_given?

    yield(self)
    force_flush
  end

  def write(value)
    @buffer.write(value)
    force_flush if @buffer.string.length > configatron.api.flush_response_at
  end

  def flush
    # Ignore flush for the moment
  end

  def force_flush
    @stream.call(@buffer.string)
    @buffer.reopen
  end
  private :force_flush
end
