class Warren::QueueBroadcastMessage # rubocop:todo Style/Documentation
  include AfterCommitEverywhere

  attr_reader :record

  def initialize(record = nil, class_name: nil, id: nil)
    if record
      @record = record
      @class_name = record.class.name
      @id = record.id
    else
      @class_name = class_name
      @id = id
    end
  end

  def queue(warren)
    after_commit { warren << self }
  end

  def routing_key
    "#{Rails.env}.queue_broadcast.#{@class_name.underscore}.#{@id}"
  end

  def payload
    [@class_name, @id].to_json
  end
end
