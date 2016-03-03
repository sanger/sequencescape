# Use this file to easily define all of your cron jobs.
#
# It's helpful, but not entirely necessary to understand cron before proceeding.
# http://en.wikipedia.org/wiki/Cron

# Example:
#
# set :output, "/path/to/my/cron_log.log"
#
# every 2.hours do
#   command "/usr/bin/some_great_command"
#   runner "MyModel.some_method"
#   rake "some:great:rake:task"
# end
#
# every 4.days do
#   runner "AnotherModel.prune_old_records"
# end

# Stores logs in eg. 2016-02-26-environment-application.log
# where: environment comes from whenever
#        application is specified when the string is used as eg. output_helper % 'application'
output_helper = "`date +%%Y-%%m-%%d`-#{environment}-%s.log"

# Learn more: http://github.com/javan/whenever

every :hour, :roles => [:app] do
  rake "tmp:carrierwave:cleanup"
end

every :hour, :roles => [:cron] do
  runner "lib/cron_scripts/import_fluidigm_data.rb", output: output_helper % 'fluidigm_import'
  runner 'lib/volume_check.rb'
end

# The following sets of services can be enabled/disabled based on environmental variables
# This allows different crons to be turned on in different environments eg. staging
# ENVs are feature based, rather than environment based to avoid leaking sangerisms
# and to let us describe or environments when we create them.
if ENV['ACCESSION']
  every 5.minutes, :roles => [:cron] do
    runner 'lib/cron_scripts/generate_sample_accessions.rb', output: output_helper % '02sample_accessions'
  end
end
