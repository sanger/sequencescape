# frozen_string_literal: true

# This file was automatically generated via `rails g record_loader`
namespace :record_loader do
  desc 'Automatically generate TagGroupAdapterType through TagGroupAdapterTypeLoader'
  task tag_group_adapter_type: :environment do
    RecordLoader::TagGroupAdapterTypeLoader.new.create!
  end
end

# Automatically run this record loader as part of record_loader:all
# Remove this line if the task should only run when invoked explicitly
task 'record_loader:all' => 'record_loader:tag_group_adapter_type'
