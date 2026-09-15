# frozen_string_literal: true

# Rake task to load ultima_primer records
namespace :record_loader do
  desc 'Automatically generate UltimaPrimer through UltimaPrimerLoader'
  task ultima_primer: :environment do
    RecordLoader::UltimaPrimerLoader.new.create!
  end
end

# Run this record loader as part of record_loader:all
task 'record_loader:all' => 'record_loader:ultima_primer'
