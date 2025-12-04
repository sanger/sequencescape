# frozen_string_literal: true
class Event::AccessioningEvent < Event
  def self.created_accession_number!(eventable, accession_type, user)
    create!(
      eventful: eventable,
      message: "Created #{accession_type} accession number",
      family: 'accessioning',
      of_interest_to: 'administrators',
      created_by: user&.login
    )
  end

  def self.updated_accession_number!(eventable, accession_type, user)
    create!(
      eventful: eventable,
      message: "Updated #{accession_type} accession data",
      family: 'accessioning',
      of_interest_to: 'administrators',
      created_by: user&.login
    )
  end
end
