# frozen_string_literal: true

# This file was automatically generated via `rails g record_loader`
# The task creation should follow the workflow creation — workflows are created within the Pipeline loader
namespace :record_loader do
  desc 'Automatically generate Task through TaskLoader'
  task task: [:environment, 'record_loader:pipeline'] do
    RecordLoader::TaskLoader.new.create!
  end
end

# Automatically run this record loader as part of record_loader:all
# Remove this line if the task should only run when invoked explicitly
task 'record_loader:all' => 'record_loader:task'
