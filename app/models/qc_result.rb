class QcResult < ApplicationRecord

  belongs_to :asset, required: true
  
  validates_presence_of :key, :value, :units
end
