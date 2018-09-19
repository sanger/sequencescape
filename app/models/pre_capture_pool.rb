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
      base.class_eval do
        self.pre_capture_pooled = true
      end
    end
  end

  # Joins requests to pools
  class PooledRequest < ApplicationRecord
    belongs_to :request
    validates_presence_of :request
    validates_uniqueness_of :request_id
    belongs_to :pre_capture_pool, inverse_of: :pooled_requests
    validates_presence_of :pre_capture_pool
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
        return if poolable_type.nil?
        grouped_requests.each do |_, requests|
          plex = requests.first.order.request_options['pre_capture_plex_level'].to_i
          offset.times { requests.map! { |r| submission.next_requests(r) } }
          pool(requests, plex)
        end
      end
    end

    private

    def poolable_type
      @pt ||= RequestType.find(submission.request_type_ids).detect { |rt| rt.request_class.pre_capture_pooled? }
    end

    def library_creation_type
      submission.request_type_ids.detect { |rt| RequestType.find(rt).request_class <= Request::LibraryCreation }
    end

    def offset
      @offset ||= (submission.request_type_ids.index(poolable_type.id) - submission.request_type_ids.index(library_creation_type))
    end

    def pool(requests, plex)
      requests.flatten.each_slice(plex) do |pooled_requests|
        PreCapturePool.create!(requests: pooled_requests)
      end
    end

    def grouped_requests
      submission.requests
                .joins(:order, asset: :map)
                .where(request_type_id: library_creation_type)
                .order('maps.column_order ASC, id ASC')
                .group_by { |r| r.order.pre_cap_group || "o#{r.order_id}" }
    end
  end
end
