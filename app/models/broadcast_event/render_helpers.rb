#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2015 Genome Research Ltd.
module BroadcastEvent::RenderHelpers
  # Controls our render.
  class Render
    def self.to_hash(event)
      {
        :uuid => event.uuid,
        :event_type => event.event_type,
        :occured_at => event.created_at,
        :user_identifier => event.user_identifier,
        :subjects => event.subjects,
        :metadata => event.metadata
      }
    end
  end

  module RenderableClassMethods
    def render_class
      Render
    end
  end
end
