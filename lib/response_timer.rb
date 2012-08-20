# This module may be used to benchmark the API processes

class ResponseTimer
  require 'java'

  class InstanceTimer
    def initialize(start,output,response,env)
      @start = start
      @output = output
      @response = response
      @env = env
    end

    def close
      @response.close if @response.respond_to?(:close) # Pass us on
      stop = Time.now
      @output.syswrite "Request: #{@env['REQUEST_METHOD']}%#{@env['REQUEST_PATH']}%#{@env["rack.input"].string}%#{stop-@start}\n"
      #@output.syswrite %Q{curl -X #{@env['REQUEST_METHOD']} -H "X_SEQUENCESCAPE_CLIENT_ID:development" -H "USER_AGENT:Ruby" -H "COOKIE:WTSISignOn=" -H "ACCEPT:application/json" -H "Content-Type: application/json" -d '#{@env["rack.input"].string}' http://localhost:3000#{@env['REQUEST_PATH']} --noproxy localhost\n}
    end

    def each(&block)
      @response.each(&block)
    end
  end

  def initialize(app,output)
    @app = app
    @output = output
    header
  end

  def call(env)
    start = Time.now
    status, headers, response = @app.call(env)
    [status, headers, InstanceTimer.new(start,@output,response,env)]
  end

  def header
    engine = defined?(RUBY_ENGINE) ? RUBY_ENGINE : 'mri'
    @output.syswrite <<-HEADER
Rails response log
Started at: #{Time.now}
Environment: #{RAILS_ENV}:R#{RUBY_VERSION}:#{File.split(Rails.root).last.capitalize}:#{engine}
------------
    HEADER
  end

end