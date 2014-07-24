class AssetAudit < ActiveRecord::Base
  include Api::AssetAuditIO::Extensions
  include Uuid::Uuidable
  include ::Io::AssetAudit::ApiIoSupport

  belongs_to :asset

  cattr_reader :per_page
  @@per_page = 500

  validates_presence_of :asset
  validates_presence_of :key
  validates_format_of :key, :with => /^[\w_]+$/i, :message => I18n.t('asset_audit.key_format'), :on => :create

end

