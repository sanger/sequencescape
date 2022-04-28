# frozen_string_literal: true
class Event::ScannedIntoLabEvent < Event # rubocop:todo Style/Documentation
  after_create :set_qc_state_pending, if: :qc_state_not_final?
  alias asset eventful

  def self.create_for_asset!(asset, location_barcode, created_by)
    create!(
      eventful: asset,
      message: "Scanned into #{location_barcode}",
      content: Date.today.to_s,
      family: 'scanned_into_lab',
      created_by: created_by
    )
  end

  def set_qc_state_pending
    asset.receptacle.qc_state = 'pending'
    asset.receptacle.save!
  end

  def qc_state_not_final?
    asset.respond_to?(:receptacle) && %w[passed failed].exclude?(asset.receptacle.qc_state)
  end
end
