# frozen_string_literal: true
class SubmittedAsset < ApplicationRecord
  belongs_to :order
  belongs_to :asset, class_name: 'Receptacle'

  validates :order, presence: { inverse_of: :submitted_assets }
  validates :asset, presence: { inverse_of: :submitted_assets }

  convert_labware_to_receptacle_for :asset
end
