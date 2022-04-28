# frozen_string_literal: true
class BroadcastEvent::AssetAudit < BroadcastEvent # rubocop:todo Style/Documentation
  seed_class AssetAudit

  def event_type
    seed.key
  end

  def user_identifier
    return seed.created_by if user.nil?

    user.email.presence || user.login
  end

  has_subject(:labware, :asset)
  has_subjects(:sample) { |audit, _e| audit.asset.contained_samples }
  has_subjects(:stock_plate) { |audit, _e| audit.asset.is_a?(Plate) ? audit.asset.original_stock_plates : [] }
  has_subjects(:study) { |audit, _e| audit.asset.studies }

  has_metadata(:message, :message)
  has_metadata(:witnessed_by, :witnessed_by)
end
