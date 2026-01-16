# frozen_string_literal: true
set :output, lambda { '2>&1 | logger -t sequencescape_cron' }

every 3.minutes do
  runner 'VolumeCheck.process'
end

every 1.hour do
  runner 'CronScripts::ImportFluidigmData.process'
  rake 'tmp:carrierwave:cleanup'
end
