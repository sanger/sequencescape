# frozen_string_literal: true

# https://github.com/simplecov-ruby/simplecov#getting-started

require 'simplecov_json_formatter'
require 'simplecov-lcov'
SimpleCov::Formatter::LcovFormatter.config.report_with_single_file = true
SimpleCov::Formatter::LcovFormatter.config.single_report_path = 'lcov.info'
SimpleCov.formatters =
  SimpleCov::Formatter::MultiFormatter.new(
    [SimpleCov::Formatter::HTMLFormatter, SimpleCov::Formatter::JSONFormatter, SimpleCov::Formatter::LcovFormatter]
  )
SimpleCov.start :rails do
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

  # Mainly here for reference, and wont be running it again
  add_filter '/lib/ability_analysis/spec_generator.rb'
end
