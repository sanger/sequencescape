# frozen_string_literal: true
# Join table linking {Batch} to {Request}
# Requests can be alocated a specific order by setting 'position'. This is
# especially useful for determining {Lane} order for {SequencingRequest}.
class BatchRequest < ApplicationRecord
  include Api::BatchRequestIo::Extensions
  include Uuid::Uuidable

  self.per_page = 500

  belongs_to :batch, inverse_of: :batch_requests
  belongs_to :request, inverse_of: :batch_request

  scope :ordered, -> { order(:position) }
  scope :at_position, ->(position) { where(position:) }

  # Ensure that any requests that are added have a position that is unique and incremental in the batch,
  # unless we're moving them around in the batch, in which case we assume it'll be valid.
  attr_accessor :sorting_requests_within_batch
  alias sorting_requests_within_batch? sorting_requests_within_batch

  delegate :requires_position?, to: :batch

  validates :position, numericality: { only_integer: true, if: :requires_position? }
  validates :position, uniqueness: { scope: :batch_id, if: :need_to_check_position? }

  # Database validates uniqueness of request_id to ensure each request is only in one batch.
  # Constraint removed here for performance reasons
  # validates_uniqueness_of :request_id, message: '%{value} is already in a batch.'

  # Sets the position on the request if it is required and not already set.
  # NB. This sets the position on each batch_request one at a time, based on the maximum position
  # used so far in the batch.
  before_validation(if: :requires_position?, unless: :position?) do |record|
    record.position = (record.batch.batch_requests.filter_map(&:position).max || 0) + 1
  end

  broadcast_with_warren

  def move_to_position!(position)
    update!(sorting_requests_within_batch: true, position: position)
  end

  private

  def need_to_check_position?
    requires_position? && !sorting_requests_within_batch?
  end
end
