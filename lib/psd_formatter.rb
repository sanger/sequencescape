class PsdFormatter < ::Logger::Formatter

  def initialize(deployment_info)
    @app_tag = "#{deployment_info.name}:#{deployment_info.version}:#{deployment_info.environment}"
    super()
  end

  def call(severity, timestamp, progname, msg)
    thread_id = Thread.current.object_id
    "(thread-#{thread_id}) [#{@app_tag}]  #{severity} -- : #{msg}\n"
  end
end
