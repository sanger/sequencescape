# frozen_string_literal: true
set :output, lambda { '2>&1 | logger -t sequencescape_cron' }

every 1.hour do
  runner 'lib/cron_scripts/import_fluidigm_data.rb'
  rake 'tmp:carrierwave:cleanup'
  runner 'lib/volume_check.rb'
end
