module Request::Statistics
  module DeprecatedMethods
    # TODO - Move these to named scope on Request
    def total_requests(request_type)
      self.requests.request_type(request_type).count
    end

    def completed_requests(request_type)
      self.requests.request_type(request_type).completed.count
    end

    def passed_requests(request_type)
      self.requests.request_type(request_type).passed.count
    end

    def failed_requests(request_type)
      self.requests.request_type(request_type).failed.count
    end

    def pending_requests(request_type)
      self.requests.request_type(request_type).pending.count
    end

    def started_requests(request_type)
      self.requests.request_type(request_type).started.count
    end

    def cancelled_requests(request_type)
      self.requests.request_type(request_type).cancelled.count
    end
  end

  class Counter
    def initialize
      @statistics = Hash.new { |h,k| h[k] = 0 }
    end

    delegate :[], :[]=, :to => :@statistics

    def total
      @statistics.values.sum
    end

    def completed
      [ 'passed', 'failed' ].map(&method(:[])).sum
    end

    def pending
      [ 'pending', 'blocked' ].map(&method(:[])).sum
    end

    [ :started, :passed, :failed, :cancelled ].each do |direct_type|
      class_eval(%Q{def #{direct_type} ; self[#{direct_type.to_s.inspect}] ; end})
    end

    def progress
      return 0 if self.passed.zero?  # If there are no passed then the progress is 0% by definition
      (self.passed * 100) / (self.total - self.failed)
    end
  end

  class Summary
    def initialize
      @counters = Hash.new { |h,k| h[k] = Counter.new }
    end

    delegate :[], :[]=, :to => :@counters

    def self.summary_counter(name)
      line = __LINE__ + 1
      class_eval(%Q{
        def #{name}
          @counters.values.map(&#{name.to_sym.inspect}).sum
        end
      }, __FILE__, line)
    end

    [ :started, :passed, :failed, :cancelled, :completed, :pending ].each do |name|
      summary_counter(name)
    end
  end

  # Returns a hash that maps from the RequestType to the information about the number of requests in various
  # states.  This is effectively summary data that can be displayed in a tabular format for the user.
  def progress_statistics
    counters  = self.all(:select => 'request_type_id, state, count(distinct requests.id) as total', :group => 'request_type_id, state')
    tabulated = Hash.new { |h,k| h[k] = Counter.new }
    tabulated.tap do
      counters.each do |request_type_state_count|
        tabulated[request_type_state_count.request_type][request_type_state_count.state] = request_type_state_count.total.to_i
      end
    end
  end

  def asset_statistics(options = {})
    counters = self.all(options.merge(:select => 'asset_id,request_type_id,state, count(*) as total', :group => 'asset_id, request_type_id, state'))
    tabulated = Hash.new { |h,k| h[k] = Summary.new }
    tabulated.tap do
      counters.each do |asset_request_type_state_count|
        tabulated[asset_request_type_state_count.asset_id.to_i][asset_request_type_state_count.request_type_id.to_i][asset_request_type_state_count.state] = asset_request_type_state_count.total.to_i
      end
    end
  end

  def sample_statistics(options = {})
    counters = self.join_asset.all(options.merge(:select => 'sample_id,request_type_id,state,count(*) as total', :group => 'sample_id, request_type_id, state'))
    tabulated = Hash.new { |h,k| h[k] = Summary.new }
    tabulated.tap do
      counters.each do |sample_request_type_state_count|
        tabulated[sample_request_type_state_count.sample_id.to_i][sample_request_type_state_count.request_type_id.to_i][sample_request_type_state_count.state] = sample_request_type_state_count.total.to_i
      end
    end
  end
end
