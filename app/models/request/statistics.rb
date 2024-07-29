# frozen_string_literal: true
module Request::Statistics
  class Counter
    def initialize(statistics = {})
      @statistics = Hash.new(0).merge(statistics)
    end

    delegate :[], :[]=, to: :@statistics

    # Cancelled requests get filtered out, as generally they are administrative decisions
    def total
      @statistics.values.sum - @statistics['cancelled']
    end

    def completed
      %w[passed failed].sum(&method(:[]))
    end

    def pending
      %w[pending blocked].sum(&method(:[]))
    end

    %i[started passed failed cancelled].each do |direct_type|
      define_method(direct_type) { @statistics[direct_type.to_s] }
    end

    # Returns each state, with is absolute and percentage contribution to the total.
    # Excluded states don't get returned, ideal for excluding pending from progress bars.
    # Note: excluded states still form part of the calculations
    def states(exclude: [])
      filtered_states = sorted_states.reject { |state, _statistics| exclude.include?(state) || state == 'cancelled' }
      filtered_states.map { |state, absolute| [state, absolute, (absolute * 100) / total] }
    end

    # Percentage of passed requests out of those which haven't been failed.
    # I believe the reason failed requests are subtracted from the total, rather than added
    # to pending, are because failed sequencing requests get duplicated, and in this case
    # it wouldn't make sense to increment progress.
    def progress
      return 0 if passed.zero? # If there are no passed then the progress is 0% by definition

      (passed * 100) / (total - failed)
    end

    private

    def sorted_states
      @statistics.sort_by { |state, _statistics| Request::Statemachine::SORT_ORDER.index(state) || state.each_byte.sum }
    end
  end

  class Summary
    def initialize
      @counters = Hash.new { |h, k| h[k] = Counter.new }
    end

    delegate :[], :[]=, to: :@counters

    def self.summary_counter(name)
      line = __LINE__ + 1
      class_eval(
        "
        def #{name}
          @counters.values.map(&#{name.to_sym.inspect}).sum
        end
      ",
        __FILE__,
        line
      )
    end

    %i[started passed failed cancelled completed pending].each { |name| summary_counter(name) }
  end

  # Returns a hash that maps from the RequestType to the information about the number of requests in various
  # states.  This is effectively summary data that can be displayed in a tabular format for the user.
  def progress_statistics # rubocop:todo Metrics/MethodLength
    counters =
      select('request_type_id, state, count(distinct requests.id) as total').group('request_type_id, state').includes(
        :request_type
      )
    tabulated = Hash.new { |h, k| h[k] = Counter.new }
    tabulated.tap do
      counters.each do |request_type_state_count|
        tabulated[request_type_state_count.request_type][
          request_type_state_count.state
        ] = request_type_state_count.total.to_i
      end
    end
  end

  # rubocop:todo Metrics/MethodLength
  def asset_statistics(wheres) # rubocop:todo Metrics/AbcSize
    counters =
      select('asset_id,request_type_id,state, count(*) as total')
        .group('asset_id, request_type_id, state')
        .includes(:request_type)
        .where(wheres)
    tabulated = Hash.new { |h, k| h[k] = Summary.new }
    tabulated.tap do
      counters.each do |asset_request_type_state_count|
        tabulated[asset_request_type_state_count.asset_id.to_i][asset_request_type_state_count.request_type_id.to_i][
          asset_request_type_state_count.state
        ] = asset_request_type_state_count.total.to_i
      end
    end
  end

  # rubocop:enable Metrics/MethodLength

  # rubocop:todo Metrics/MethodLength
  def sample_statistics_new # rubocop:todo Metrics/AbcSize
    counters =
      join_asset
        .select('sample_id,request_type_id,state,count(*) as total')
        .group('sample_id, request_type_id, state')
        .includes(:request_type)
    tabulated = Hash.new { |h, k| h[k] = Summary.new }
    tabulated.tap do
      counters.each do |sample_request_type_state_count|
        tabulated[sample_request_type_state_count.sample_id.to_i][sample_request_type_state_count.request_type_id.to_i][
          sample_request_type_state_count.state
        ] = sample_request_type_state_count.total.to_i
      end
    end
  end
  # rubocop:enable Metrics/MethodLength
end
