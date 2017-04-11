# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2012,2013,2014,2015,2016 Genome Research Ltd.

class AmqpObserver < ActiveRecord::Observer
  class_attribute :exchange_interface, instance_accessor: true
  # Observe not only the records but their metadata too, otherwise we may miss changes.
  observe(
    :order, :submission, :request, :plate_purpose,
    :study, :study_sample, :sample, :aliquot, :tag,
    :project,
    :asset, :asset_link, :well_attribute,
    Metadata::Base,
    :batch, :batch_request,
    :role, Role::UserRole,
    :reference_genome,
    :messenger,
    :broadcast_event
  )

  module BunnyExchange
    # The combination of Bunny & Mongrel means that, unless you start & stop the Bunny connection,
    # the Mongrel process will start killing threads because of too many open files.  Run handles
    # all this for us.
    def self.exchange
      Bunny.run(configatron.amqp.url, spec: '09', frame_max: configatron.amqp.fetch(:maximum_frame, 0)) do |client|
        yield client.exchange('psd.sequencescape', passive: true)
      end
    rescue Bunny::ConnectionTimeout, StandardError => exception
      Rails.logger.error { "Unable to broadcast: #{exception.message}\n#{exception.backtrace.join("\n")}" }
    end
  end

  module HareExchange
    def self.exchange
      client = MarchHare.connect(uri: configatron.amqp.url)
      begin
        ch = client.create_channel
        exchange = ch.topic('psd.sequencescape', durable: true)
        yield exchange
      ensure
        client.close
      end
    rescue MarchHare::ConnectionRefused, StandardError => exception
      Rails.logger.error { "Unable to broadcast: #{exception.message}\n#{exception.backtrace.join("\n")}" }
    end
  end

  # Switch our AMQP client depending on which is included
  # MarchHare in case of Jruby, Bunny of MRI
  self.exchange_interface = if defined?(JRuby)
                              HareExchange
                            else
                              BunnyExchange
                            end

    # Ensure we capture records being saved as well as deleted.
    #
    # NOTE: Oddly you can't alias_method the after_destroy, it has to be physically defined!
    class_eval('def after_save(record) ; self << record ; true ; end')
    class_eval('def after_destroy(record) ; record.class.render_class.associations.each {|a,_| record.send(a) } ; self << record ; true ; end')

  # To prevent ActiveRecord::Observer doing something unwanted when we test this, we pull
  # out the implementation in a module (which can be tested) and leave the rest behind.
  module Implementation
    # A transaction is (potentially) a bulk send of messages and hence we can create a buffer that
    # will be written to during changes.  But transactions can be nested, which means that only the
    # very outer one should do any publishing.
    #
    #--
    # What follows looks complicated but is specialised to deal with a 'return' being called from
    # within the block.  In that case the 'return' causes the method to return and *not* to execute
    # any code after 'yield' in the code below.  Therefore you have the situation where the database
    # transaction has been committed but the AMQP broadcast has not happened.  But the 'ensure' block
    # is always called, so we assume the transaction to be good (i.e. commit) unless an exception is
    # raised (when it is marked as bad), and broadcast our buffer iff the transaction is good and
    # there's stuff to broadcast.
    #++
    def transaction
      # JG: This code took me a while to get my head around.
      # If thread buffer is unset (Ie. we are in the outermost transaction) then
      # create a new MostRecentBuffer and also set current buffer equal to this
      # If thread buffer is set (Ie. we are in a nested transaction) do nothing,
      # current_buffer will be nil
      Thread.current[:buffer] ||= (current_buffer = MostRecentBuffer.new(self))
      transaction_good = true
      yield
    rescue => exception
      # Something has gone wrong. We'll be rolling back to record this so we don't broadcast
      # then reraise the error
      transaction_good = false
      raise
    ensure
      # Everything is complete, grab an exchange and broadcast but only if
      # 1) The transaction is still flagged as good
      # 2) current buffer is not blank (ie. we have something to broadcast, and aren't in an inner transaction)
      activate_exchange do |exchange|
        current_buffer.each do |record|
          publish_to(exchange, record)
        end
      end if transaction_good and not current_buffer.blank?
      # The transaction is over, if current buffer isn't nil (ie. we're in the outermost transaction)
      # clean up after yourself and set the thread buffer to nil.
      Thread.current[:buffer] = nil unless current_buffer.nil?
    end

    def <<(record)
      buffer << record
      self # Ensure we can chain these if necessary!
    end

    # Converts metadata entries to their owner records, if necessary
    def determine_record_to_broadcast(record, &block)
      case
      when record.nil? then nil # Do nothing if we have no record.
        # This occurs with roles with no authorizable, but may also happen in cases where we have
        # orphaned records.
      when record.is_a?(WellAttribute)  then yield(record.well,  nil)
      when record.is_a?(Metadata::Base) then yield(record.owner, nil)
      when record.is_a?(Role)           then determine_record_to_broadcast(record.authorizable, &block)
      when record.is_a?(Role::UserRole) then determine_record_to_broadcast(record.role, &block)
      else                                   yield(record, record)
      end
    end

    # A simple buffer class that will only retain the most recent version of any object pushed
    # into it.  Assumes that equality is what you want for checking for things, which works fine
    # with ActiveRecord.
    class MostRecentBuffer
      def initialize(observer)
        @observer, @updated, @deleted = observer, Set.new, Set.new
      end

      delegate :determine_record_to_broadcast, to: :@observer

      def each(&block)
        @updated.group_by(&:first).each do |model, pairs|
          # Regardless of what the scoping says, we're going by ID so we always want to do what
          # the standard model does.  If we need eager loading we'll add it.
          model.unscoped do
            model = model.including_associations_for_json if model.respond_to?(:including_associations_for_json)
            pairs.map(&:last).in_groups_of(configatron.amqp.burst_size).each { |group| model.find(group.compact).map(&block) }
          end
        end
        @deleted.each(&block)
      end

      def <<(record)
        tap do
          determine_record_to_broadcast(record) do |record_to_broadcast, record_for_deletion|
            pair = [record_to_broadcast.class, record_to_broadcast.id]
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

      delegate :activate_exchange, :publish_to, :determine_record_to_broadcast, to: :@observer
      private :activate_exchange, :publish_to

      def <<(record)
        activate_exchange do |exchange|
          determine_record_to_broadcast(record) do |record_to_broadcast, record_for_deletion|
            Rails.logger.warn { "AmqpObserver called outside transaction: #{caller.join("\n")}" }

            if record.destroyed?
              publish_to(exchange, record_for_deletion) if record_for_deletion.present?
            else
              publish_to(exchange, record_to_broadcast)
            end
          end
        end
      end
    end

    def publish_to(exchange, record)
      exchange.publish(
        MultiJson.dump(record),
        routing_key: record.routing_key || "#{Rails.env}.saved.#{record.class.name.underscore}.#{record.id}",
        persistent: configatron.amqp.persistent
      )
    end

    # The buffer that should be written to is either the one created within the transaction, or it is a
    # wrapper around ourselves.
    def buffer
      Thread.current[:buffer] || Proxy.new(self)
    end
    private :buffer

    # We may have either Bunny of MArchHare depending on Ruby version.
    # Unfortunately their interfaces are slightly different
    def activate_exchange(&block)
      exchange_interface.exchange(&block)
    end
  end
  include Implementation
end

class ActiveRecord::Base
  class << self
    def transaction_with_amqp(opts = {}, &block)
      transaction_without_amqp(opts) { AmqpObserver.instance.transaction(&block) }
    end
    alias_method_chain(:transaction, :amqp)
  end
  def routing_key;
    nil;
  end
end if ActiveRecord::Base.observers.include?(:amqp_observer)
