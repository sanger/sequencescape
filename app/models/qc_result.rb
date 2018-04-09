# frozen_string_literal: true

# QcResult
class QcResult < ApplicationRecord
  belongs_to :asset, required: true

  validates :key, :value, :units, presence: true
end
