# frozen_string_literal: true

# This file was automatically generated via `rails g record_loader`
namespace :record_loader do
  desc 'Automatically generate RobotProperty through RobotPropertyLoader'
  # Dependant on robots being created first
  task robot_property: [:environment, 'record_loader:robot'] do
    RecordLoader::RobotPropertyLoader.new.create!
  end
end

# Automatically run this record loader as part of record_loader:all
# Remove this line if the task should only run when invoked explicitly
task 'record_loader:all' => 'record_loader:robot_property'
