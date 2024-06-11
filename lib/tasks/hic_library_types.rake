# frozen_string_literal: true
# Create hic library types for ToL

namespace :hic_library_types do
  task create: :environment do
    hic_library_type = LibraryType.find_by(name: 'Hi-C')

    request_types = hic_library_type.request_types

    ['Hi-C - Arima v2', 'Hi-C – Qiagen', 'Hi-C – OmniC', 'Hi-C – Arima v1', 'Hi-C – Dovetail'].each do |name|
      next if LibraryType.find_by(name:)

      LibraryType.create!(name:, request_types:)
      puts "Library type created for #{name}"
    end
  end
end
