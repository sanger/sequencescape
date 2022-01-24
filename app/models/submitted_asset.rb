# frozen_string_literal: true
class SubmittedAsset < ApplicationRecord
  belongs_to :order
  belongs_to :asset, class_name: 'Receptacle'


  convert_labware_to_receptacle_for :asset
end
