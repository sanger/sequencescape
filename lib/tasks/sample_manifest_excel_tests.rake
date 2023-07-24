# frozen_string_literal: true
require 'rake/testtask'

namespace :sample_manifest_excel do
  desc 'Run all sample manifest excel tests'
  task tests: :environment do
    Rake::TestTask.new(:all_tests) do |t|
      t.libs << 'test'
      t.pattern = Rails.root.join('test', 'lib', 'sample_manifest_excel', '**', '*_test.rb')
      t.ruby_opts = ['-W0']
    end
    Rake::Task['all_tests'].execute
  end
end
