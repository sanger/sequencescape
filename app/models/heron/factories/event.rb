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

        @broadcast_event ||= event_class.new(seed: @seed, properties: @params[:event])
      end

      def event_class
        EVENT_CLASSES[@params.dig(:event, :event_type)]
      end

      def check_broadcast_event
        return if errors.count.positive?
        return unless broadcast_event
        return if broadcast_event.valid?

        # In Rails 6.1 object.errors returns ActiveModel::Errors, in Rails 6.0 it returns a Hash
        broadcast_event.errors.each { |error| errors.add error.attribute, error.message }
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
