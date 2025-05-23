# frozen_string_literal: true

# This file was automatically generated via `rails g record_loader`
# The descriptor creation should follow the task creation
# Tasks creation should follow the workflow creation — workflows are created within the Pipeline loader
#
namespace :record_loader do
  desc 'Automatically generate Descriptor through DescriptorLoader'
  task descriptor: [:environment, 'record_loader:pipeline', 'record_loader:task'] do
    RecordLoader::DescriptorLoader.new.create!
  end
end

# Automatically run this record loader as part of record_loader:all
# Remove this line if the task should only run when invoked explicitly
task 'record_loader:all' => 'record_loader:descriptor'
