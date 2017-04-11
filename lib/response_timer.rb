# This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2012 Genome Research Ltd.
# This module may be used to benchmark the API processes

class ResponseTimer
  require 'java'

  class InstanceTimer
    def initialize(start, output, response, env)
      @start = start
      @output = output
      @response = response
      @env = env
    end

    def close
      @response.close if @response.respond_to?(:close) # Pass us on
      stop = Time.now
      @output.syswrite "Request: #{@env['REQUEST_METHOD']}%#{@env['REQUEST_URI']}%#{@env["rack.input"].string}%#{stop - @start}\n"
    end

    def each(&block)
      @response.each(&block)
    end
  end

  def initialize(app, output)
    @app = app
    @output = output
    header
  end

  def call(env)
    start = Time.now
    status, headers, response = @app.call(env)
    [status, headers, InstanceTimer.new(start, @output, response, env)]
  end

  def header
    engine = defined?(RUBY_ENGINE) ? RUBY_ENGINE : 'mri'
    @output.syswrite <<-HEADER
Rails response log
Started at: #{Time.now}
Environment: #{Rails.env}:R#{RUBY_VERSION}:#{File.split(Rails.root).last.capitalize}:#{engine}
------------
    HEADER
  end
end
