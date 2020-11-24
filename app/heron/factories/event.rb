module Heron
  module Factories
    # Factory class to create Heron tube racks
    class Event
      include ActiveModel::Model

      EVENT_CLASSES = {
        "#{BroadcastEvent::PlateCherrypicked::EVENT_TYPE}" => BroadcastEvent::PlateCherrypicked
      }
      validates :broadcast_event, presence: true
      validate :check_broadcast_event

      def initialize(params, seed)
        @params = params
        @seed = seed
      end

      def broadcast_event
        return unless event_class
        @broadcast_event ||= event_class.new(seed: @seed, properties: @params.dig(:event))
      end

      def event_class
        EVENT_CLASSES.dig(@params.dig(:event, :event_type))
      end

      def check_broadcast_event
        return if errors.count.positive?
        return unless broadcast_event
        unless broadcast_event.valid?
          broadcast_event.errors.each {|k,v| errors.add(k,v) }
        end
      end

      def save
        return false unless valid?
        return false unless broadcast_event

        ActiveRecord::Base.transaction do
          broadcast_event.save
        end
        true
      end


    end
  end
end
