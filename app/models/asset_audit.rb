# frozen_string_literal: true
# Created by external applications (especially asset audits) to represent
# work done.
# @see https://github.com/sanger/asset_audits AssetAudits, also known as process tracker and lab activity
class AssetAudit < ApplicationRecord
  include Uuid::Uuidable

  # include ::Io::AssetAudit::ApiIoSupport

  belongs_to :asset, class_name: 'Labware'

  self.per_page = 500

  validates :asset, :key, presence: true
  validates :key, format: { with: /\A[\w_]+\z/i, message: I18n.t('asset_audit.key_format'), on: :create }

  after_create :broadcast_event

  private

  def broadcast_event
    BroadcastEvent::AssetAudit.create!(seed: self, user: User.find_by(login: created_by), created_at: created_at)
  end
end
