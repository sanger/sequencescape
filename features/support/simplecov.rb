# frozen_string_literal: true

require 'simplecov'
SimpleCov.start :rails do
  skip '/test/'
  skip '/config/'
  skip '/coverage/'
  skip '/data/'
  skip '/db/'
  skip '/doc/'
  skip '/log/'
  skip '/public/'
  skip '/script/'
  skip '/features/'
  skip '/vendor/'
  skip '/tmp/'

  enable_coverage :branch

  # You can skip here to add anything else you don't want to cover

  # Mainly here for reference, and wont be running it again
  skip '/lib/ability_analysis/spec_generator.rb'
end
