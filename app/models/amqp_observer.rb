class AmqpObserver < ActiveRecord::Observer
  observe :study, :project, :study_sample, :sample, :asset_link, :request, :asset, :aliquot

  def after_save(record)
    buffer << record
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
