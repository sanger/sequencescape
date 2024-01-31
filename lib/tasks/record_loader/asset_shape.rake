# frozen_string_literal: true

namespace :record_loader do
  desc 'Automatically generate AssetShapes and Maps through AssetShapesLoader'
  task asset_shape: :environment do
    RecordLoader::AssetShapeLoader.new.create!
  end
end

# Automatically run this record loader as part of record_loader:all
# Remove this line if the task should only run when invoked explicitly
task 'record_loader:all' => 'record_loader:asset_shape'
