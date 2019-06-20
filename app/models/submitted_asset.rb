class SubmittedAsset < ApplicationRecord
  belongs_to :order
  belongs_to :asset, class_name: 'Receptacle'

  validates_presence_of :order, inverse_of: :submitted_assets
  validates_presence_of :asset, inverse_of: :submitted_assets

  convert_labware_to_receptacle_for :asset
end
