class AmqpObserver < ActiveRecord::Observer
  observe(
    :order, :submission, :request,
    :study, :study_sample, :sample, :aliquot, :tag,
    :project,
    :asset, :asset_link
  )

  # The basic behaviour is to buffer any record that we receive for broadcast.
  def buffer_record(record)
    buffer << record
  end
  private :buffer_record

  # Ensure we capture records being saved as well as deleted.
  #
  # NOTE: Oddly you can't alias_method the after_destroy, it has to be physically defined!
  [ :after_save, :after_destroy ].each do |name|
    class_eval(%Q{def #{name}(record) ; buffer_record(record) ; end})
  end

  def transaction(&block)
    Thread.current[:buffer] ||= (current_buffer = [])
    yield.tap do
      current_buffer.map(&method(:<<)) unless current_buffer.nil?
    end
  ensure
    Thread.current[:buffer] = nil unless current_buffer.nil?
  end

  def buffer
    Thread.current[:buffer] || self
  end
  private :buffer

  def <<(record)
    exchange.publish(record.to_json, :key => "#{Rails.env}.saved.#{record.class.name.underscore}.#{record.id}")
  rescue => exception
    Rails.log.error("Unable to broadcast #{record.class.name}(#{record.id}): #{exception.message}\n#{exception.backtrace.join("\n")}")
  end

  def exchange
    @exchange ||= configure_exchange
    @exchange
  end
  private :exchange

  def configure_exchange
    client = Bunny.new(configatron.amqp_url, :spec => '09')
    client.start
    client.exchange('psd.sequencescape', :passive => true)
  end
  private :configure_exchange
end

class ActiveRecord::Base
  class << self
    def transaction_with_amqp(&block)
      transaction_without_amqp { AmqpObserver.instance.transaction(&block) }
    end
    alias_method_chain(:transaction, :amqp)
  end
end
