
class Event::ScannedIntoLabEvent < Event
  after_create :set_qc_state_pending, unless: :test?
  alias_method :asset, :eventful

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
    asset.qc_pending
  end

  def test?
    (asset.qc_state == 'passed' || asset.qc_state == 'failed')
  end
end
