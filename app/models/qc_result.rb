# frozen_string_literal: true

# QcResult
class QcResult < ApplicationRecord
  belongs_to :asset, required: true
  after_save :update_asset

  validates :key, :value, :units, presence: true

  def update_asset
    asset.update_from_qc(self)
  end
end
