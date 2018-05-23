require 'syslog/logger'
require 'ostruct'

class PsdFormatter < Syslog::Logger::Formatter

  def initialize(deployment_info)
    info = OpenStruct.new(deployment_info)
    @app_tag = "#{info.name}:#{info.version}:#{info.environment}"
    super()
  end

  def call(severity, timestamp, progname, msg)
    thread_id = Thread.current.object_id
    "(thread-#{thread_id}) [#{@app_tag}]  #{severity} -- : #{msg}\n"
  end
end
