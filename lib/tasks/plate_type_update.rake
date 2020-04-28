# frozen_string_literal: true

namespace :plate_type do
  desc 'Automatically generate absent plate types'
  task update: :environment do
    RecordLoader::PlateTypeLoader.new.create!
  end
end
