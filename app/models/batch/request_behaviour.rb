# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2011,2012,2014,2015 Genome Research Ltd.

module Batch::RequestBehaviour
  def self.included(base)
    base.class_eval do
      has_one :batch_request, inverse_of: :request, dependent: :destroy
      has_one :batch, through: :batch_request, inverse_of: :requests

      scope :include_for_batch_view, -> { includes(:batch_request, :asset, :target_asset, :request_metadata, :comments) }

      # For backwards compatibility
      def batch_requests; [batch_request].compact; end

      def batches; [batch].compact; end

      # Identifies all requests that are not part of a batch.
      # Note: we join, rather than includes due to custom select limitations.
      scope :unbatched, ->() {
        joins('LEFT OUTER JOIN batch_requests ON batch_requests.request_id = requests.id')
        .readonly(false)
        .where(batch_requests: { request_id: nil })
      }

      delegate :position, to: :batch_request, allow_nil: true
    end
  end

  def with_batch_id
    yield batch.id if batch.present?
  end

  def recycle_from_batch!
    ActiveRecord::Base.transaction do
      return_for_inbox!
      batch_request.destroy if batch_request.present?
      save!
    end
  end

  def create_batch_request!(*args)
    # I think this is actually deprecated
    create_batch_request(args)
  end

  def return_for_inbox!
    # Valid for started, cancelled and pending batches
    # Will raise an exception outside of this
    cancel! if started?
    detach! unless pending?
  end
end
