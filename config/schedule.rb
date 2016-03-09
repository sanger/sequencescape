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

# PRREVIEW:
# ACCESSION=yup whenever --set environment=testing
# Generation:
# ACCESSION=yup whenever --set environment=testing&mailto=example@example.com -i application_environment -r app,cron

# If using cpaistrano, the following can be helpful in configuration
# set :whenever_environment, defer { stage }
# set :whenever_identifier, defer { "#{application}_#{stage}" }
# set :whenever_variables  { "environment=#{fetch :whenever_environment}&mailto=example@example.com&accession=true" }
# require "whenever/capistrano"

# job_template can be used to wrap jobs in an external script.
# This allows setting up of eg. stopfiles and filters.
# eg job_template=/my/filter/script :job :stop
# Learn more: http://github.com/javan/whenever

set :application, 'sequencescape'
# mailto sets the email address for cron notifications. Can be specifies as an ENV, or passed in at the commend line
set :mailto, ENV.fetch('MAILTO',nil)
# If accession if provided, the accessioning crons will run
set :accession, ENV.fetch('ACCESSION',false)
# The command to execute if a stop_file is stale
set :stale_command, "echo 'Stale stop file for #{environment}_#{application}_:stop'"
set :stop_dir, nil

# Stores logs in eg. 2016-02-26-environment-task.log
# where: environment comes from whenever
#        task is specified when the string is used as eg. output_helper % 'task'
output_helper = "`date +%%Y-%%m-%%d`-#{environment}-%s.log"


# Checks if the :stop file is more than :age minutes old and generates an alert
# Note: Stop files are not created by the default :job_template
# Outputs eg: (WARN) staging_sequencescape_five_min.stop untouched since Sun 26 Feb 2012 16:17:03 GMT
job_type :check_stale, "find :stop_dir/#{environment}_#{application}_:task -mmin +:age -printf '(WARN) %p untouched since %Tc\n' 2> /dev/null"


if mailto
  env :MAILTO, mailto
end

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
if accession
  every 5.minutes, :roles => [:cron] do
    runner 'lib/cron_scripts/generate_sample_accessions.rb', output: output_helper % '02sample_accessions'
  end
  every 15.minutes, :roles => [:cron] do
    check_stale 'accessioning', age: 15 if stop_dir
  end
end
