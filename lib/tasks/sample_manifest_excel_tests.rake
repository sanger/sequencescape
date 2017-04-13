
require 'rake/testtask'

namespace :sample_manifest_excel do
  desc 'Run all sample manifest excel tests'
  task :tests do
    Rake::TestTask.new(:all_tests) do |t|
      t.libs << 'test'
      t.pattern = File.join(Rails.root, 'test', 'lib', 'sample_manifest_excel', '**', '*_test.rb')
    end
    Rake::Task['all_tests'].execute
  end
end
