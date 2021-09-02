# frozen_string_literal: true
module BroadcastEvent::RenderHelpers
  # Controls our render.
  class Render
    def self.to_hash(event)
      {
        uuid: event.uuid,
        event_type: event.event_type,
        occured_at: event.created_at,
        user_identifier: event.user_identifier,
        subjects: event.subjects,
        metadata: event.metadata
      }
    end
  end

  module RenderableClassMethods # rubocop:todo Style/Documentation
    def render_class
      Render
    end
  end
end
