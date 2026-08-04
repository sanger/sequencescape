# frozen_string_literal: true

# https://github.com/simplecov-ruby/simplecov#getting-started
# https://github.com/simplecov-ruby/simplecov#using-simplecov-for-centralized-config

require 'simplecov'
require 'simplecov_json_formatter'
require 'simplecov-lcov'

SimpleCov::Formatter::LcovFormatter.config.report_with_single_file = true
SimpleCov::Formatter::LcovFormatter.config.single_report_path = 'lcov.info'
SimpleCov.formatters =
  SimpleCov::Formatter::MultiFormatter.new(
    [SimpleCov::Formatter::HTMLFormatter, SimpleCov::Formatter::JSONFormatter, SimpleCov::Formatter::LcovFormatter]
  )

SimpleCov.load_profile 'rails'
SimpleCov.enable_coverage :branch

# You can skip here to add anything else you don't want to cover
SimpleCov.skip '/test/'
SimpleCov.skip '/config/'
SimpleCov.skip '/coverage/'
SimpleCov.skip '/data/'
SimpleCov.skip '/db/'
SimpleCov.skip '/doc/'
SimpleCov.skip '/log/'
SimpleCov.skip '/public/'
SimpleCov.skip '/script/'
SimpleCov.skip '/features/'
SimpleCov.skip '/vendor/'
SimpleCov.skip '/tmp/'

# Mainly here for reference, and wont be running it again
SimpleCov.skip '/lib/ability_analysis/spec_generator.rb'
