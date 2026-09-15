# frozen_string_literal: true

# Rake task to load ultima_application records
namespace :record_loader do
  desc 'Automatically generate UltimaApplication through UltimaApplicationLoader'
  task ultima_application: [:environment, 'record_loader:ultima_primer', 'record_loader:ultima_preset'] do
    RecordLoader::UltimaApplicationLoader.new.create!
  end
end

# Run this record loader as part of record_loader:all
task 'record_loader:all' => 'record_loader:ultima_application'
