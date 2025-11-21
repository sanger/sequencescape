# frozen_string_literal: true

# Rake task to load ultima_globals records
namespace :record_loader do
  desc 'Automatically generate UltimaGlobal through UltimaGlobalLoader'
  task ultima_globals: :environment do
    RecordLoader::UltimaGlobalLoader.new.create!
  end
end

# Run this record loader as part of record_loader:all
task 'record_loader:all' => 'record_loader:ultima_globals'
