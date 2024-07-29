# frozen_string_literal: true

# Ensure events point at the appropriate class
class UpdateEventsEventableTypes < ActiveRecord::Migration[5.1]
  def up # rubocop:disable Metrics/AbcSize
    Event.where(family: 'scanned_into_lab').update_all(eventful_type: 'Labware')
    Event::PlateCreationEvent.update_all(eventful_type: 'Labware')
    Event::SampleManifestEvent.where(eventful_type: 'Asset').update_all(eventful_type: 'Labware')
    ExternalReleaseEvent.update_all(eventful_type: 'Receptacle')
    Event.where('family LIKE "picked_well_%"').update_all(eventful_type: 'Receptacle')
    Event::SequenomLoading.where(family: 'update_fluidigm_plate').update_all(eventful_type: 'Labware')
    Event::SequenomLoading.where(family: %w[update_gender_markers update_sequenom_count]).update_all(
      eventful_type: 'Receptacle'
    )
    Event::AssetSetQcStateEvent.update_all(eventful_type: 'Receptacle')

    # Remaining events prioritize receptacles over labware
    Event
      .where(eventful_type: 'Asset')
      .joins('INNER JOIN receptacles ON receptacles.id = eventful_id')
      .update_all(eventful_type: 'Receptacle')
    Event
      .where(eventful_type: 'Asset')
      .joins('INNER JOIN labware ON labware.id = eventful_id')
      .update_all(eventful_type: 'Labware')
  end

  def down
    # We can't roll back once new events have been created
    raise ActiveRecord::IrreversibleMigration
  end
end
