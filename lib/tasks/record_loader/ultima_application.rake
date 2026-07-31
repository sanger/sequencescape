# frozen_string_literal: true

namespace :record_loader do
  desc 'Automatically generate UltimaApplication through UltimaApplicationLoader'
  task ultima_application: :environment do
    RecordLoader::UltimaApplicationLoader.new.create!
  end
end

task 'record_loader:all' => 'record_loader:ultima_application'
