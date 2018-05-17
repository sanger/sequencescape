# frozen_string_literal: true

# QcResult
class QcResult < ApplicationRecord
  include Api::Messages::QcResultIO::Extensions

  belongs_to :asset, required: true

  validates :key, :value, :units, presence: true

  after_commit :broadcast_qc_result, on: [:create, :update]

  private

  def broadcast_qc_result
    Messenger.new(target: self, template: 'QcResultIO', root: 'qc_result').broadcast
  end
end
