module Heron
  module Factories
    module Concerns
      # This module provides a building interface to support creation of events in a
      # factory
      module Eventful
        def build_events(seed)
          return unless @params[:events]
          return if errors.count.positive?

          params_for_event.map do |event_params|
            Heron::Factories::Event.new(event_params, seed)
          end
        end

        def params_for_event
          return unless @params[:events]

          @params[:events]
        end

        def add_all_errors_from_events(events)
          events.each do |event|
            event.errors.each do |k, v|
              errors.add(k, v)
            end
          end
        end

        def rollback_for_events(events)
          @output_result = false
          add_all_errors_from_events(events)
          raise ActiveRecord::Rollback
        end
      end
    end
  end
end
