#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2007-2011 Genome Research Ltd.
module Event::PlateEvents
  def gel_qc_date
    event_date('gel_analysed')
  end

  def pico_date
    event_date('pico_analysed')
  end

  def qc_started_date
    event_date('create_dilution_plate_purpose')
  end

  def sequenom_stamp_date
    event_date('create_for_sequenom')
  end

  def event_date(key)
    event = self.events.find_by_family(key)
    return event.content if event

    nil
  end

end
