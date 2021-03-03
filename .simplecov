SimpleCov.start 'rails' do
  add_filter '/test/'
  add_filter '/config/'
  add_filter '/coverage/'
  add_filter '/data/'
  add_filter '/db/'
  add_filter '/doc/'
  add_filter '/log/'
  add_filter '/public/'
  add_filter '/script/'
  add_filter '/features/'
  add_filter '/vendor/'
  add_filter '/tmp/'

  enable_coverage :branch
  enable_for_subprocesses true
  at_fork do |pid|
    # This needs a unique name so it won't be ovewritten
    SimpleCov.command_name "#{SimpleCov.command_name} (subprocess: #{pid})"
    # be quiet, the parent process will be in charge of output and checking coverage totals
    SimpleCov.print_error_status = false
    SimpleCov.minimum_coverage 0
    # start
    SimpleCov.start
  end

  # You can add_filter here to add anything else you don't want to cover

  # Mainly here for reference, and wont be running it again
  add_filter '/lib/ability_analysis/spec_generator.rb'
end
