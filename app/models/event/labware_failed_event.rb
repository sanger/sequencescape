# frozen_string_literal: true

# Labware failed event
class Event::LabwareFailedEvent < Event
  # after_create :set_qc_state_pending, if: :qc_state_not_final?
  alias asset eventful

  def self.create_for_asset!(asset, failure_id, created_by)
    create!(
      eventful: asset,
      message: "Labware failed for reason: #{failure_id}",
      content: Time.zone.today.to_s,
      family: 'labware_failure',
      created_by:
    )
  end
end
