class Warren::Message
  attr_reader :record

  def initialize(record)
    @record = record
  end

  def routing_key
    record.routing_key || "#{Rails.env}.saved.#{record.class.name.underscore}.#{record.id}"
  end

  def payload
    MultiJson.dump(record)
  end
end
