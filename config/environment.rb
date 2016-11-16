# Load the Rails application.
begin_path = $:.dup
puts "==BEGIN=="
puts begin_path
require File.expand_path('../application', __FILE__)
mid_path = $:.dup
puts "==MID=="
puts mid_path
puts "==MID=DELTA="
(mid_path-begin_path).each do |path|
  puts "+#{path}"
end
(begin_path-mid_path).each do |path|
  puts "-#{path}"
end
# Initialize the rails application
Sequencescape::Application.initialize!
end_path = $:.dup
puts "==END=="
puts end_path
puts "==END=DELTA="
(end_path-begin_path).each do |path|
  puts "+#{path}"
end
(begin_path-end_path).each do |path|
  puts "-#{path}"
end
