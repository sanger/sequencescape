class PreCapturePool < ActiveRecord::Base

  # We build pre capture groups at submission so that they are not affected by failing of wells or
  # re-arraying.

  module Poolable
    def self.included(base)
      base.class_eval do
        has_one :pre_capture_pool, :through => :pooled_request
        has_one :pooled_request, :dependent=>:destroy, :class_name => 'PreCapturePool::PooledRequest', :foreign_key => :request_id
      end
    end
  end

  class PooledRequest < ActiveRecord::Base
    belongs_to :request
    validates_presence_of :request_id
    validates_uniqueness_of :request_id
    belongs_to :pre_capture_pool
    validates_presence_of :pre_capture_pool_id
  end

  include Uuid::Uuidable
  has_many :requests, :through => :pooled_requests
  has_many :pooled_requests, :dependent => :destroy

  class Builder

    attr_reader :submission

    def initialize(submission)
      @submission = submission
    end

    def poolable_type
      @pt ||= RequestType.find(submission.request_type_ids).detect {|rt| rt.request_class.include?(Poolable)}
    end
    private :poolable_type

    def library_creation_type
      submission.request_type_ids.detect {|rt| RequestType.find(rt).request_class <= Request::LibraryCreation }
    end
    private :library_creation_type

    def offset
      @offset ||= (submission.request_type_ids.index(poolable_type.id) - submission.request_type_ids.index(library_creation_type))
    end
    private :offset

    def pool(requests,plex)
      requests.flatten.each_slice(plex) do |pooled_requests|
        PreCapturePool.create!(:requests=>pooled_requests)
      end
    end
    private :pool

    def build!
      ActiveRecord::Base.transaction do
        return if poolable_type.nil?
        submission.requests.find(:all, {
          :joins => ['JOIN orders ON orders.id = requests.order_id','JOIN assets ON assets.id = requests.asset_id','JOIN maps ON maps.id = assets.map_id'],
          :conditions=>['request_type_id = ?', library_creation_type ],
          :order=>'maps.column_order ASC, id ASC'
        }).group_by {|r| r.order.pre_cap_group||"o#{r.order_id}"}.each do |_,requests|
          plex   = requests.first.order.request_options['pre_capture_plex_level'].to_i
          offset.times { requests.map!{|r| submission.next_requests(r) }}
          pool(requests, plex)
        end
      end
    end

  end

end
