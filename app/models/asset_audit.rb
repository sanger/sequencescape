
class AssetAudit < ApplicationRecord
  include Uuid::Uuidable
  include ::Io::AssetAudit::ApiIoSupport

  belongs_to :asset

  self.per_page = 500

  validates_presence_of :asset, :key
  validates_format_of :key, with: /\A[\w_]+\z/i, message: I18n.t('asset_audit.key_format'), on: :create

  # Disabled in the initial events release. One enabling ensure historical audits
  # get broadcast
  # after_create :broadcast_event

  private

  def broadcast_event
    BroadcastEvent::AssetAudit.create!(seed: self, user: User.find_by(login: created_by), created_at: created_at)
  end
end
