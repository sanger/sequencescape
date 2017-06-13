require 'cucumber/formatter/progress'
class DebugFormatter < Cucumber::Formatter::Progress
  def initialize(runtime, io, options)
    super
    @start_time = time
    @runtime = runtime
    @io = io
    @options = options
  end

  def before_feature(feature)
    @io.puts "#{feature.short_name} (Start@#{time-@start_time})"
    @feature_start = time
  end

  def before_feature_element(scenario)
    @io.print "┣━ #{scenario.name} (Start@#{time-@start_time})"
    @element_start = time
  end

  def after_feature_element(scenario)
    char = case scenario.status
           when :passed then '✓'
           when :failed then '❌'
           else '?'
           end
    @io.puts " Took #{time - @element_start} #{char}"
  end

  def after_feature(feature)
    @io.puts "┗━ Took #{time - @feature_start}"
  end

  def progress(_)
  end
  # Timecop can overide Time.now. If
  # now_without_mock_time is defined, use that instead.
  def time
    if Time.respond_to?(:now_without_mock_time)
      Time.now_without_mock_time
    else
      Time.now
    end
  end

end
