# frozen_string_literal: true
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

  def fluidigm_stamp_date
    event_key = PlatesHelper.event_family_for_pick(configatron.fetch(:sta_plate_purpose_name))
    event_date(event_key)
  end

  def event_date(key)
    events.loaded? ? event_from_object(key) : event_from_database(key)
  end

  def event_from_database(key)
    events.where(family: key).pluck(:content).last
  end
  private :event_from_database

  def event_from_object(key)
    events.reverse.detect { |e| e.family == key }.try(:content)
  end
  private :event_from_object
end
