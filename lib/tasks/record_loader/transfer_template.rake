# frozen_string_literal: true

namespace :record_loader do
  desc 'Automatically generate TransferTemplate through TransferTemplateLoader'
  task transfer_template: :environment do
    RecordLoader::TransferTemplateLoader.new.create!
  end
end

# Automatically run this record loader as part of record_loader:all
# Remove this line if the task should only run when invoked explicitly
task 'record_loader:all' => 'record_loader:transfer_template'
