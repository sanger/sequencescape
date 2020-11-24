module Heron
  module Factories
    module Concerns
      module Eventful

        def build_events(seed)
          return unless @params[:events]
          return if errors.count.positive?

          @events ||= params_for_event.map do |event_params|
            Heron::Factories::Event.new(event_params, seed)
          end
        end

        def params_for_event
          return unless @params[:events]
          return @params[:events]
        end
      end
    end
  end
end