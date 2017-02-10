# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2015 Genome Research Ltd.

class BroadcastEvent::AssetAudit < BroadcastEvent
  seed_class AssetAudit

  def event_type
    seed.key
  end

  def user_identifier
    return seed.created_by if user.nil?
    user.email.blank? ? user.login : user.email
  end

  has_subject(:labware, :asset)
  has_subjects(:sample) { |audit, _e| audit.asset.contained_samples }
  has_subjects(:stock_plate) { |audit, _e| audit.asset.is_a?(Plate) ? audit.asset.original_stock_plates : [] }
  has_subjects(:study) { |audit, _e| audit.asset.studies }

  has_metadata(:message, :message)
  has_metadata(:witnessed_by, :witnessed_by)
end
