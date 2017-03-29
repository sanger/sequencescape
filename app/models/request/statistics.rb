# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2011,2012,2014,2015 Genome Research Ltd.

module Request::Statistics
  module DeprecatedMethods
    # TODO: - Move these to named scope on Request
    def total_requests(request_type)
      requests.request_type(request_type).distinct.count(:id)
    end

    def completed_requests(request_type)
      requests.request_type(request_type).completed.distinct.count(:id)
    end

    def passed_requests(request_type)
      requests.request_type(request_type).passed.distinct.count(:id)
    end

    def failed_requests(request_type)
      requests.request_type(request_type).failed.distinct.count(:id)
    end

    def pending_requests(request_type)
      requests.request_type(request_type).pending.distinct.count(:id)
    end

    def started_requests(request_type)
      requests.request_type(request_type).started.distinct.count(:id)
    end

    def cancelled_requests(request_type)
      # distinct.count(:id) in rails_4
      requests.request_type(request_type).cancelled.distinct.count(:id)
    end

    def total_requests_report
      requests.group(:request_type_id).count
    end
  end

  class Counter
    def initialize
      @statistics = Hash.new { |h, k| h[k] = 0 }
    end

    delegate :[], :[]=, to: :@statistics

    def total
      @statistics.values.sum
    end

    def completed
      ['passed', 'failed'].map(&method(:[])).sum
    end

    def pending
      ['pending', 'blocked'].map(&method(:[])).sum
    end

    [:started, :passed, :failed, :cancelled].each do |direct_type|
      class_eval("def #{direct_type} ; self[#{direct_type.to_s.inspect}] ; end")
    end

    def progress
      return 0 if passed.zero? # If there are no passed then the progress is 0% by definition
      (passed * 100) / (total - failed)
    end
  end

  class Summary
    def initialize
      @counters = Hash.new { |h, k| h[k] = Counter.new }
    end

    delegate :[], :[]=, to: :@counters

    def self.summary_counter(name)
      line = __LINE__ + 1
      class_eval("
        def #{name}
          @counters.values.map(&#{name.to_sym.inspect}).sum
        end
      ", __FILE__, line)
    end

    [:started, :passed, :failed, :cancelled, :completed, :pending].each do |name|
      summary_counter(name)
    end
  end

  # Returns a hash that maps from the RequestType to the information about the number of requests in various
  # states.  This is effectively summary data that can be displayed in a tabular format for the user.
  def progress_statistics
    counters  = select('request_type_id, state, count(distinct requests.id) as total').group('request_type_id, state').includes(:request_type)
    tabulated = Hash.new { |h, k| h[k] = Counter.new }
    tabulated.tap do
      counters.each do |request_type_state_count|
        tabulated[request_type_state_count.request_type][request_type_state_count.state] = request_type_state_count.total.to_i
      end
    end
  end

  def asset_statistics(wheres)
    counters = select('asset_id,request_type_id,state, count(*) as total').group('asset_id, request_type_id, state').includes(:request_type).where(wheres)
    tabulated = Hash.new { |h, k| h[k] = Summary.new }
    tabulated.tap do
      counters.each do |asset_request_type_state_count|
        tabulated[asset_request_type_state_count.asset_id.to_i][asset_request_type_state_count.request_type_id.to_i][asset_request_type_state_count.state] = asset_request_type_state_count.total.to_i
      end
    end
  end

  def sample_statistics_new
    counters = join_asset.select('sample_id,request_type_id,state,count(*) as total').group('sample_id, request_type_id, state').includes(:request_type)
    tabulated = Hash.new { |h, k| h[k] = Summary.new }
    tabulated.tap do
      counters.each do |sample_request_type_state_count|
        tabulated[sample_request_type_state_count.sample_id.to_i][sample_request_type_state_count.request_type_id.to_i][sample_request_type_state_count.state] = sample_request_type_state_count.total.to_i
      end
    end
  end
end
