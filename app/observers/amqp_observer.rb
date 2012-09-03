class AmqpObserver < ActiveRecord::Observer
  # Observe not only the records but their metadata too, otherwise we may miss changes.
  observe(
    :order, :submission, :request,
    :study, :study_sample, :sample, :aliquot, :tag,
    :project,
    :asset, :asset_link, :well_attribute,
    Metadata::Base,
    :billing_event,
    :batch, :batch_request
  )

  # Ensure we capture records being saved as well as deleted.
  #
  # NOTE: Oddly you can't alias_method the after_destroy, it has to be physically defined!
  [ :after_save, :after_destroy ].each do |name|
    class_eval(%Q{def #{name}(record) ; self << record ; true ; end})
  end

  # To prevent ActiveRecord::Observer doing something insane when we test this, we pull
  # out the implementation in a module (which can be tested) and leave the rest behind.
  module Implementation
    def self.included(base)
      base.class_eval do
        attr_reader :exchange
        private :exchange
      end
    end

    # A transaction is (potentially) a bulk send of messages and hence we can create a buffer that
    # will be written to during changes.  But transactions can be nested, which means that only the
    # very outter one should do any publishing.
    def transaction(&block)
      Thread.current[:buffer] ||= (current_buffer = MostRecentBuffer.new(self))
      yield.tap do
        activate_exchange do
          current_buffer.map(&method(:publish))
        end unless current_buffer.blank?
      end
    ensure
      Thread.current[:buffer] = nil unless current_buffer.nil?
    end

    def <<(record)
      buffer << record
      self  # Ensure we can chain these if necessary!
    end

    # Converts metadata entries to their owner records, if necessary
    def determine_record_to_broadcast(record)
      record_to_broadcast, record_for_deletion = case
      when record.is_a?(WellAttribute)  then [ record.well,  nil ]
      when record.is_a?(Metadata::Base) then [ record.owner, nil ]
      else [ record, record ]
      end

      yield(record_to_broadcast, record_for_deletion)
    end
    private :determine_record_to_broadcast

    # A simple buffer class that will only retain the most recent version of any object pushed
    # into it.  Assumes that equality is what you want for checking for things, which works fine
    # with ActiveRecord.
    class MostRecentBuffer
      def initialize(observer)
        @observer, @updated, @deleted = observer, Set.new, Set.new
      end

      delegate :determine_record_to_broadcast, :to => :@observer

      def map(&block)
        @updated.group_by(&:first).each do |model, pairs|
          model = model.including_associations_for_json if model.respond_to?(:including_associations_for_json)
          pairs.map(&:last).in_groups_of(configatron.amqp.burst_size).each { |group| model.find(group.compact).map(&block) }
        end
        @deleted.map(&block)
      end

      def <<(record)
        self.tap do
          determine_record_to_broadcast(record) do |record_to_broadcast, record_for_deletion|
            pair = [ record_to_broadcast.class, record_to_broadcast.id ]
            if record.destroyed?
              @updated.delete(pair)
              @deleted << record_for_deletion if record_for_deletion.present?
            else
              @updated << pair
            end
          end
        end
      end

      def blank?
        @updated.empty? and @deleted.empty?
      end
    end

    # A very simply proxy around the observer such that it will ensure the exchange is activated.
    # This should mean that `AmqpObserver.instance << record` will work, even without the surrounding
    # transaction.
    class Proxy
      def initialize(observer)
        @observer = observer
      end

      delegate :activate_exchange, :publish, :determine_record_to_broadcast, :to => :@observer
      private :activate_exchange, :publish

      def <<(record)
        activate_exchange do
          determine_record_to_broadcast(record) do |record_to_broadcast, record_for_deletion|
            if record.destroyed?
              publish(record_for_deletion) if record_for_deletion.present?
            else
              publish(record_to_broadcast)
            end
          end
        end
      end
    end

    def publish(record)
      exchange.publish(
        record.to_json,
        :key        => "#{Rails.env}.saved.#{record.class.name.underscore}.#{record.id}",
        :persistent => configatron.amqp.persistent
      )
    end
    private :publish

    # The buffer that should be written to is either the one created within the transaction, or it is a
    # wrapper around ourselves.
    def buffer
      Thread.current[:buffer] || Proxy.new(self)
    end
    private :buffer

    # The combination of Bunny & Mongrel means that, unless you start & stop the Bunny connection,
    # the Mongrel process will start killing threads because of too many open files.  This method,
    # therefore, enables transactional support for connecting to the exchange.
    def activate_exchange(&block)
      return yield unless @exchange.nil?

      client = Bunny.new(configatron.amqp.url, :spec => '09')
      begin
        client.start
        @exchange = client.exchange('psd.sequencescape', :passive => true)
        yield
      ensure
        @exchange = nil
        client.stop
      end
    rescue Qrack::ConnectionTimeout, StandardError => exception
      Rails.logger.debug { "Unable to broadcast: #{exception.message}\n#{exception.backtrace.join("\n")}" }
    end
    private :activate_exchange
  end
  include Implementation
end

class ActiveRecord::Base
  class << self
    def transaction_with_amqp(&block)
      transaction_without_amqp { AmqpObserver.instance.transaction(&block) }
    end
    alias_method_chain(:transaction, :amqp)
  end
end if ActiveRecord::Base.observers.include?(:amqp_observer)
