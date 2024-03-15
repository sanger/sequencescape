# frozen_string_literal: true
module Heron
  module Factories
    # Factory class to create Events (for the moment only PlateCherrypicked)
    class Event
      include ActiveModel::Model

      EVENT_CLASSES = { BroadcastEvent::PlateCherrypicked::EVENT_TYPE.to_s => BroadcastEvent::PlateCherrypicked }.freeze
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

      def check_broadcast_event #rubocop:todo Metrics/AbcSize
        return if errors.count.positive?
        return unless broadcast_event
        return if broadcast_event.valid?

        # In Rails 6.1 object.errors returns ActiveModel::Errors, in Rails 6.0 it returns a Hash
        if broadcast_event.errors.is_a?(ActiveModel::Errors)
          broadcast_event.errors.each { |error| errors.add error.attribute, error.message }
        else
          object.errors.each { |key, value| errors.add key, value }
        end
      end

      def save
        return false unless valid?
        return false unless broadcast_event

        ActiveRecord::Base.transaction { broadcast_event.save }
        true
      end
    end
  end
end
