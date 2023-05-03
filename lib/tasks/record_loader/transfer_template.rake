# frozen_string_literal: true

namespace :record_loader do
  desc 'Automatically generate TransferTemplate through TransferTemplateLoader'
  task transfer_template: :environment do
    RecordLoader::TransferTemplateLoader.new.create!
  end
end
