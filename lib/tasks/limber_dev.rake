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

      desc 'Create 4 GBS stock plates'
      task gbs: ['limber:setup'] do
        seeder = WorkingSetup::StandardSeeder.new([['GBS Stock', 4]])
        seeder.create_purposes
      end

      desc 'Generate a mock GbS tag set if required'
      task gbs_tag_set: ['working:env_check', :environment] do
        next if TagLayoutTemplate.find_by(name: 'GbS Tag Set')
        tg = TagGroup.create!(name: 'GbS Test - 384') do |group|
          group.tags.build(OligoEnumerator.new(384).each_with_index.map { |oligo, map_id| { oligo: oligo, map_id: map_id + 1 } })
        end
        TagLayoutTemplate.create!(
          name: 'GbS Tag Set',
          direction_algorithm: 'TagLayout::InColumns',
          walking_algorithm: 'TagLayout::WalkWellsOfPlate',
          tag_group: tg, tag2_group: tg
        )
      end

      desc 'Add tag platesfor GbS: dev only'
      task gbs_tag_plates: ['working:env_check', :environment, 'limber:dev:setup:gbs_tag_set'] do
        seeder = WorkingSetup::StandardSeeder.new([])
        seeder.tag_plates(lot_type: 'Pre Stamped Tags - 384', template: 'GbS Tag Set')
      end
    end
  end
end
