# frozen_string_literal: true

# A pre-capture pool is a group of requests which will be pooled together midway
# through library preparation, particularly prior to capture in the indexed-sequence
# capture (ISC) pipelines
# We build pre capture groups at submission so that they are not affected by failing of wells or
# re-arraying.
class PreCapturePool < ApplicationRecord
  # INclude in request classes which allow pre-capture pooling
  module Poolable
    def self.included(base)
      base.class_eval { self.pre_capture_pooled = true }
    end
  end

  # Joins requests to pools
  class PooledRequest < ApplicationRecord
    belongs_to :request
    validates :request, presence: true
    validates :request_id, uniqueness: true
    belongs_to :pre_capture_pool, inverse_of: :pooled_requests
    validates :pre_capture_pool, presence: true
  end

  include Uuid::Uuidable

  has_many :pooled_requests, dependent: :destroy, inverse_of: :pre_capture_pool
  has_many :requests, through: :pooled_requests

  class Builder
    attr_reader :submission

    def initialize(submission)
      @submission = submission
    end

    def build!
      ActiveRecord::Base.transaction do
        return unless poolable?

        # We find the library creation requests sorted in column order
        # and then walk downstream until we get to the poolable requests.
        # It is these requests that get assigned to a pre-capture pool.
        # We can't jump to the poolable requests directly, as they may not
        # be sorted in column order.
        grouped_requests.each do |_, requests|
          plex = requests.first.order.request_options['pre_capture_plex_level'].to_i
          poolable_requests = requests.flat_map { |request| walk_to_pooled_request(request) }
          pool(poolable_requests, plex)
        end
      end
    end

    private

    def walk_to_pooled_request(request)
      return request if request.pre_capture_pooled?

      next_requests = request.next_requests
      raise StandardError, "Could not find pooled request for request #{request.id}" if next_requests.empty?

      next_requests.map { |next_request| walk_to_pooled_request(next_request) }
    end

    def poolable?
      RequestType.find(submission.order_request_type_ids).detect { |rt| rt.request_class.pre_capture_pooled? }.present?
    end

    def library_creation_type
      submission.request_type_ids.detect { |rt| RequestType.find(rt).request_class <= Request::LibraryCreation }
    end

    def pool(requests, plex)
      requests.flatten.each_slice(plex) { |pooled_requests| PreCapturePool.create!(requests: pooled_requests) }
    end

    def grouped_requests
      submission
        .requests
        .joins(:order, asset: :map)
        .where(request_type_id: library_creation_type)
        .order('maps.column_order ASC, id ASC')
        .group_by { |r| r.order.pre_cap_group || "o#{r.order_id}" }
    end
  end
end
