# frozen_string_literal: true
namespace :benchmark do
  task plate_creation: :environment do
    $stdout.puts 'Warming up...'
    15.times { PlatePurpose.find_by(name: 'Stock Plate').create! }

    start = Time.zone.now
    $stdout.puts "Starting #{start}"
    30.times do
      PlatePurpose.find_by(name: 'Stock Plate').create!
      $stdout.print '.'
    end
    $stdout.puts
    $stdout.puts "Took #{Time.zone.now - start}"
  end
end
