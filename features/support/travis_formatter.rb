class TravisFormatter
  attr_reader :io
  def initialize(step_mother, io, options)
    @io = io
  end

  def before_feature(feature)
    io.print "\nFeature: #{feature.short_name}"
  end

  def after_step(step)
    if step.status == :passed
      io.print '.'
    elsif step.status == :skipped
      # Do nothing
    else
      io.print "\nFAILED: #{step.name}"
      if step.exception
        io.puts step.exception.message
        io.puts step.exception.backtrace
      else
        # HUh
      end
    end
  end
end
