# This module may be used to benchmark the API processes

class ResponseTimer

  def initialize(app,output)
    @app = app
    @output = output
    header
  end

  def close
    @response.close if @response.respond_to?(:close) # Pass us on
    stop = Time.now
    @output.syswrite "Response Took: #{stop-@start}\n"
  end

  def call(env)
    @output.syswrite "Request: #{env['REQUEST_METHOD']},#{env['REQUEST_PATH']}\n"
    @start = Time.now
    @status, @headers, @response = @app.call(env)
    [@status, @headers, self]
  end

  def each(&block)
    @response.each(&block)
  end

  def header
    @output.syswrite <<-HEADER
Rails response log
Started at: #{Time.now}
Environment: #{RAILS_ENV}:R#{RUBY_VERSION}:#{File.split(Rails.root).last.capitalize}:#{RUBY_ENGINE}
------------
    HEADER
  end

end
