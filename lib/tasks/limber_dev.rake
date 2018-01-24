# frozen_string_literal: true

# We'll try and do this through the API with the live version
require './lib/oligo_enumerator'

namespace :limber do
  namespace :dev do
    namespace :setup do
      desc 'Create all limber pre-requisite plates'
      task all: [:standard, :scrna, :rna, :gbs]

      desc 'Create 4 LB Cherrypick plates'
      task standard: ['limber:setup'] do
        seeder = WorkingSetup::StandardSeeder.new([['LB Cherrypick', 4]])
        seeder.create_purposes
      end

      desc 'Create 4 scRNA Stock plates'
      task scrna: ['limber:setup'] do
        seeder = WorkingSetup::StandardSeeder.new([['scRNA Stock', 4]])
        seeder.create_purposes
      end

      desc 'Create 4 LBR Cherrypick plates'
      task rna: ['limber:setup'] do
        seeder = WorkingSetup::StandardSeeder.new([['LBR Cherrypick', 4]])
        seeder.create_purposes
      end

      desc 'Create 4 LB Cherrypick plates'
      task gbs: ['limber:setup'] do
        seeder = WorkingSetup::StandardSeeder.new([['GBS Stock', 4]])
        seeder.create_purposes
      end
    end
  end
end
