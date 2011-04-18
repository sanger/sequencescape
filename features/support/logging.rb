# This is an around filter that will mark the start and end of each scenario in the log file, making
# it easier to track the statements.
Around do |scenario, block|
  padding = '=' * (([ 100, scenario.name.length + 20 ].max - scenario.name.length) / 2 - 1)

  begin
    Rails.logger.info([ padding, 'START:', scenario.name, "#{ padding }=" ].join(' '))
    block.call
  ensure
    Rails.logger.info([ padding, 'FINISH:', scenario.name, padding ].join(' '))
  end
end
