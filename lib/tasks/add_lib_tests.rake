# Adding test/lib directory to rake test.

require "rake/testtask"

namespace :test do
  desc "Test tests/lib/* code"
  Rake::TestTask.new(lib: 'test:prepare') do |t|
    t.libs << "test"
    t.pattern = File.join(Rails.root, "test", "lib", "**", "*_test.rb")
  end
end

Rake::Task[:test].enhance ["test:lib"]
