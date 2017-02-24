# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2013,2015 Genome Research Ltd.

class PreCapturePool < ActiveRecord::Base
  # We build pre capture groups at submission so that they are not affected by failing of wells or
  # re-arraying.

  module Poolable
    def self.included(base)
      base.class_eval do
        has_one :pre_capture_pool, through: :pooled_request, inverse_of: :pooled_requests
        has_one :pooled_request, dependent: :destroy, class_name: 'PreCapturePool::PooledRequest', foreign_key: :request_id, inverse_of: :request
      end
    end
  end

  class PooledRequest < ActiveRecord::Base
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
      @pt ||= RequestType.find(submission.request_type_ids).detect { |rt| rt.request_class.include?(Poolable) }
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
