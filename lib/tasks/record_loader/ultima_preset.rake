# frozen_string_literal: true

# Rake task to load ultima_preset records
namespace :record_loader do
  desc 'Automatically generate UltimaPreset through UltimaPresetLoader'
  task ultima_preset: :environment do
    RecordLoader::UltimaPresetLoader.new.create!
  end
end

# Run this record loader as part of record_loader:all
task 'record_loader:all' => 'record_loader:ultima_preset'
