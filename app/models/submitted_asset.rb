class SubmittedAsset < ActiveRecord::Base
  belongs_to :order
  belongs_to :asset

  validates_presence_of :order
  validates_presence_of :asset
end
