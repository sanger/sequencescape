# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2012,2015 Genome Research Ltd.

class Event::ScannedIntoLabEvent < Event
  after_create :set_qc_state_pending, unless: :test?
  alias_method :asset, :eventful

  def self.create_for_asset!(asset, location)
    create!(
      eventful: asset,
      message: "Scanned into #{location.name}",
      content: Date.today.to_s,
      family: 'scanned_into_lab'
    )
  end

  def set_qc_state_pending
    asset.qc_pending
  end

  def test?
    (asset.qc_state == 'passed' || asset.qc_state == 'failed')
  end
end
