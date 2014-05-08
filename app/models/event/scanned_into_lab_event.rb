class Event::ScannedIntoLabEvent < Event
  after_create :set_qc_state_pending, :unless => :test?
  alias_method :asset, :eventful

  def self.create_for_asset!(asset, location)
    self.create!(
      :eventful => asset,
      :message => "Scanned into #{location.name}",
      :content => Date.today.to_s,
      :family => "scanned_into_lab"
    )

  end

  def set_qc_state_pending
    self.asset.qc_pending
  end

  def test?
    return (self.asset.qc_state == "passed" || self.asset.qc_state == "failed")
  end
end