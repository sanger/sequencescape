# frozen_string_literal: true
##
# A lot represents a received batch of consumables (eg. tag plates)
# that can be assumed to share some level of QC.

class Lot < ApplicationRecord
  module Template
    def self.included(base)
      base.class_eval { belongs_to :lot }
    end
  end

  # include Api::LotIO::Extensions
  include Uuid::Uuidable

  belongs_to :lot_type
  belongs_to :user
  belongs_to :template, polymorphic: true
  belongs_to :tag_layout_template,
             ->(lot) { lot.template_type == 'TagLayoutTemplate' ? all : none },
             foreign_key: :template_id,
             inverse_of: false

  has_many :qcables, inverse_of: :lot

  has_many :stamps, inverse_of: :lot

  validates :lot_number, :lot_type, :user, :template, :received_at, presence: true
  validates :lot_number, uniqueness: { case_sensitive: false }

  validate :valid_template?

  delegate :valid_template_class, :target_purpose, to: :lot_type

  scope :include_lot_type, -> { includes(:lot_type) }
  scope :include_template, -> { includes(:template) }
  scope :with_lot_number, ->(lot_number) { where(lot_number:) }

  scope :with_qc_asset,
        ->(qc_asset) do
          return none if qc_asset.nil?

          sibling = qc_asset.transfers_as_destination.first.source
          tag2_siblings = Tag2Layout.where(plate_id: qc_asset.id).pluck(:source_id)

          asset_ids = [qc_asset.id, sibling.id, tag2_siblings].flatten

          includes(:qcables).where(qcables: { asset_id: asset_ids }).where.not(qcables: { state: 'exhausted' })
        end

  private

  def valid_template?
    return false if lot_type.blank?
    return true if template.is_a?(valid_template_class)

    errors.add(
      :template,
      "is not an appropriate type for this lot. Received #{template.class} expected #{valid_template_class}."
    )
    false
  end
end
