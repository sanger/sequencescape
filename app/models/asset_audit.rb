# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2012,2015,2016 Genome Research Ltd.

class AssetAudit < ActiveRecord::Base
  include Api::AssetAuditIO::Extensions
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
