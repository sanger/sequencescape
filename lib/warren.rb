
#
# Module Warren provides connection pooling for RabbitMQ Connections
#
module Warren
  def self.construct(type:, url: nil, frame_max: 0, heartbeat: 30)
    case type
    when :test then Warren::Test.new
    when :log then Warren::Log.new
    when :broadcast then Warren::Broadcast.new(url: url, frame_max: 0, heartbeat: heartbeat)
    else raise StandardError, "Unknown type warren: #{type}"
    end
  end
end
