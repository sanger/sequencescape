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