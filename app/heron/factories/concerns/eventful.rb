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
      end
    end
  end
end
