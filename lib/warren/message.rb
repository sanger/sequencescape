class Warren::Message # rubocop:todo Style/Documentation
  attr_reader :record

  def initialize(record)
    @record = record
  end

  def routing_key
    if record.respond_to?(:routing_key)
      record.routing_key
    else
      "#{Rails.env}.saved.#{record.class.name.underscore}.#{record.id}"
    end
  end

  def payload
    MultiJson.dump(record)
  end
end
