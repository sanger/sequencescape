# frozen_string_literal: true

# Rake task to load ultima_tag_group and ultima_tag records
namespace :record_loader do
  desc 'Automatically generate UltimaTagGroup through UltimaTagGroupLoader'
  task ultima_tag_group: [:environment, 'record_loader:tag_group'] do
    RecordLoader::UltimaTagGroupLoader.new.create!
  end
end

# Run this record loader as part of record_loader:all
task 'record_loader:all' => 'record_loader:ultima_tag_group'
