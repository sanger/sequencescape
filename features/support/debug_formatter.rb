# frozen_string_literal: true

require 'cucumber/formatter/progress'
class DebugFormatter < Cucumber::Formatter::Progress
  def initialize(config)
    super
    @start_time = time
    @runtime = runtime
    @io = config.out_stream

    config.on_event :test_case_started do |event|
      if @feature != event.test_case.feature
        after_feature(@feature) if @feature
        @feature = event.test_case.feature
        before_feature(event.test_case.feature)
      end
      before_feature_element(event.test_case)
    end

    config.on_event :test_case_finished do |event|
      after_feature_element(event)
    end
  end

  def before_feature(feature)
    @io.puts "#{feature.name} (Start@#{time - @start_time})"
    @feature_start = time
  end

  def before_feature_element(scenario)
    @io.print "┣━ #{scenario.name} (Start@#{time - @start_time})"
    @element_start = time
  end

  def after_feature_element(event)
    # Event results seem to have a duration built in, but it appears
    # to be significantly shorter than actual execution time.
    @io.puts " Took #{time - @element_start} #{event.result}"
  end

  def after_feature(_feature)
    @io.puts "┗━ Took #{time - @feature_start}"
  end

  def progress(_); end

  # Timecop can overide Time.now. If
  # now_without_mock_time is defined, use that instead.
  def time
    if Time.respond_to?(:now_without_mock_time)
      Time.now_without_mock_time
    else
      Time.current
    end
  end
end
