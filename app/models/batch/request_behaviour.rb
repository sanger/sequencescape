# frozen_string_literal: true
module Batch::RequestBehaviour
  def self.included(base) # rubocop:todo Metrics/MethodLength
    base.class_eval do
      has_one :batch_request, inverse_of: :request, dependent: :destroy
      has_one :batch, through: :batch_request, inverse_of: :requests

      scope :include_for_batch_view,
            -> { includes(:batch_request, :asset, :target_asset, :request_metadata, :comments) }

      # For backwards compatibility
      def batch_requests
        [batch_request].compact
      end

      def batches
        [batch].compact
      end

      # Identifies all requests that are not part of a batch.
      # Note: we join, rather than includes due to custom select limitations.
      scope :unbatched,
            -> do
              joins('LEFT OUTER JOIN batch_requests ON batch_requests.request_id = requests.id').readonly(false).where(
                batch_requests: {
                  request_id: nil
                }
              )
            end

      delegate :position, to: :batch_request, allow_nil: true
    end
  end

  def with_batch_id
    yield batch.id if batch.present?
  end

  def recycle_from_batch!
    ActiveRecord::Base.transaction do
      return_for_inbox!
      batch_request.presence&.destroy
      save!
    end
  end

  def return_for_inbox!
    # Valid for started, cancelled and pending batches
    # Will raise an exception outside of this
    cancel! if started?
    detach! unless pending?
  end
end
