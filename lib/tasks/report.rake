# frozen_string_literal: true

# Namespace for simple report taksks
namespace :report do
  desc 'Generate information about purpose classes and their usage'
  task purposes: :environment do
    Purpose.descendants.each do |klass|
      puts '=' * 80
      puts klass.name
      puts '-' * 80
      indirect = klass.where.not(type: klass.name)
      direct = Purpose.where(type: klass.name)
      puts "Used (direct): #{direct.count}"
      puts "Used (subclasses): #{indirect.count}"
      puts "Last used (direct): #{Labware.where(plate_purpose_id: direct).maximum(:created_at)}"
      puts "Last used (subclasses): #{Labware.where(plate_purpose_id: indirect).maximum(:created_at)}"
      puts '-' * 80
      puts 'Purposes using this class directly:'
      direct.pluck(:name).each(&method(:puts))
    end
  end
end
