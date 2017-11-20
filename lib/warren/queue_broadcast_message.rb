class Warren::QueueBroadcastMessage
  attr_reader :record

  def initialize(record)
    @record = record
  end

  def routing_key
    "#{Rails.env}.queue_broadcast.#{record.class.name.underscore}.#{record.id}"
  end

  def payload
    [record.class.name, record.id].to_json
  end
end
