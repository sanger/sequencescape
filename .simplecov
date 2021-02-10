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

  # You can add_filter here to add anything else you don't want to cover

  at_exit do
    result = SimpleCov.result
    result.command_name = "#{result.command_name}.#{$PID}"
    result.format!
  end
end
