#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2016 Genome Research Ltd.
class LibraryEvent < BroadcastEvent::LibraryEventBase

  def event_type
    properties[:event_type]
  end

  def event_type=(event_type)
    self.properties ||= {}
    properties[:event_type] = event_type
  end

end
