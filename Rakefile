# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require(File.join(File.dirname(__FILE__), 'config', 'boot'))

require 'rake'
require 'rake/testtask'
require 'rake/rdoctask'
require 'tasks/rails'

begin
  require 'ci/reporter/rake/cucumber' # HACK: lib/tasks/ci_setup_cucumber_replacement.rake
  require 'ci/reporter/rake/test_unit'
rescue LoadError => exception
  # Ignore this, you simply don't have the file!
end

begin
  require 'delayed/tasks'
rescue LoadError
  STDERR.puts "Run `rake gems:install` to install delayed_job"
end

begin
  require 'parallel_tests/tasks'
#   Setup:
#     rake parallel:create
#     rake parallel:prepare
#   Run:
#     rake parallel:test          # Test::Unit
#     rake parallel:spec          # RSpec
#     rake parallel:features      # Cucumber
rescue LoadError
  # just ignore it (because we have excluded the "test" gembundle group)
end


task :test => ["test:units", "test:functionals"]
