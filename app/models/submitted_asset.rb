class SubmittedAsset < ActiveRecord::Base
  belongs_to :submission
  belongs_to :asset

  validates_presence_of :submission
  validates_presence_of :asset
end
