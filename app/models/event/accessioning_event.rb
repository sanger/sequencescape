# frozen_string_literal: true
class Event::AccessioningEvent < Event
  # Indicates that an accessionable entity has been assigned an accession number.
  #
  # Usage example:
  #   sample.events.assigned_accession_number!('sample', 'ENA123456', user)
  def self.assigned_accession_number!(eventable, accession_type, accession_number, user)
    create!(
      eventful: eventable,
      message: "Assigned #{accession_type} accession number",
      content: accession_number,
      family: 'accessioning',
      of_interest_to: 'administrators',
      created_by: user&.login
    )
  end

  # TODO: Create an updated_accessioned_data! event that indicates that the data associated with
  # an accessioned entity has been updated.
end
