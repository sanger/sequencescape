# frozen_string_literal: true

# This file was automatically generated via `rails g record_loader`
namespace :record_loader do
  desc 'Automatically generate PipelineRequestInformationType through PipelineRequestInformationTypeLoader'
  task pipeline_request_information_type: [
    :environment,
    'record_loader:pipeline',
    'record_loader:request_information_type'
  ] do
    RecordLoader::PipelineRequestInformationTypeLoader.new.create!
  end
end

# Automatically run this record loader as part of record_loader:all
# Remove this line if the task should only run when invoked explicitly
task 'record_loader:all' => 'record_loader:pipeline_request_information_type'
