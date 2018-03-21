# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2012,2015,2016 Genome Research Ltd.

class BatchRequest < ApplicationRecord
  include Api::BatchRequestIO::Extensions
  include Uuid::Uuidable

  self.per_page = 500

  belongs_to :batch, inverse_of: :batch_requests
  belongs_to :request, inverse_of: :batch_request

  scope :ordered, -> { order(:position) }
  scope :at_position, ->(position) { where(position: position) }

  # Ensure that any requests that are added have a position that is unique and incremental in the batch,
  # unless we're moving them around in the batch, in which case we assume it'll be valid.
  attr_accessor :sorting_requests_within_batch
  alias_method(:sorting_requests_within_batch?, :sorting_requests_within_batch)

  delegate :requires_position?, to: :batch

  validates_numericality_of :position, only_integer: true, if: :requires_position?
  validates_uniqueness_of :position, scope: :batch_id, if: :need_to_check_position?

  # Database validates uniqueness of request_id to ensure each request is only in one batch.
  # Constraint removed here for performance reasons
  # validates_uniqueness_of :request_id, message: '%{value} is already in a batch.'
  before_validation(if: :requires_position?, unless: :position?) do |record|
    record.position = (record.batch.batch_requests.map(&:position).compact.max || 0) + 1
  end

  broadcast_via_warren

  def move_to_position!(position)
    update_attributes!(sorting_requests_within_batch: true, position: position)
  end

  private

  def need_to_check_position?
    requires_position? && !sorting_requests_within_batch?
  end
end
