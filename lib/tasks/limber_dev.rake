# frozen_string_literal: true

# We'll try and do this through the API with the live version
require './lib/oligo_enumerator'

namespace :limber do
  namespace :dev do
    task env_check: :environment do
      unless Rails.env.development?
        puts "CAUTION! You are running this task in the #{Rails.env} environment."
        puts 'This script is intended for the development environment only.'
        puts 'Running this task in test WILL cause failures, and could cause issues in other environments.'
        puts 'Are you sure you wish to continue? (Y for yes)'
        exit unless STDIN.gets.chomp == 'Y'
      end
    end

    namespace :setup do
      desc 'Create all limber pre-requisite plates'
      task all: %i[standard scrna rna gbs heron]

      desc 'Create 4 LB Cherrypick plates'
      task standard: ['limber:setup'] do
        seeder = WorkingSetup::StandardSeeder.new([['LB Cherrypick', 4]])
        seeder.create_purposes
      end

      desc 'Create 4 GnT Stock plates'
      task gnt: ['limber:setup'] do
        seeder = WorkingSetup::StandardSeeder.new([['GnT Stock', 4]])
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

      desc 'Create 4 Heron stock plates'
      task heron: ['limber:setup'] do
        seeder = WorkingSetup::StandardSeeder.new([['LHR RT', 4]])
        seeder.create_purposes
      end

      desc 'Create 4 GBS stock plates with submissions'
      task gbs_submission: ['limber:dev:setup:gbs'] do
        plates = Purpose.find_by(name: 'GBS Stock').plates.order(id: :desc).limit(4)
        template = SubmissionTemplate.find_by!(name: 'Limber-Htp - GBS')
        plates.each do |plate|
          order =
            template.new_order(
              assets: plate.wells,
              study: Study.first!,
              project: Project.first!,
              user: User.first,
              request_options: {
                primer_panel_name: 'Dummy Panel',
                library_type: 'GBS',
                fragment_size_required_from: 100,
                fragment_size_required_to: 200
              }
            )
          sub = Submission.create!(name: plate.human_barcode, user: User.first, orders: [order])
          sub.built!
          Delayed::Worker.new.work_off
        end
      end

      desc 'Generate a mock GbS tag set if required'
      task gbs_tag_set: ['limber:dev:env_check', :environment] do
        next if TagLayoutTemplate.find_by(name: 'GbS Tag Set A')

        ('A'..'D').each_with_index do |set, index|
          tg =
            TagGroup.create!(name: "GbS Test - #{set}") do |group|
              group.tags.build(
                OligoEnumerator
                  .new(384, index * 384)
                  .each_with_index
                  .map { |oligo, map_id| { oligo:, map_id: map_id + 1 } }
              )
            end
          TagLayoutTemplate.create!(
            name: "GbS Tag Set #{set}",
            direction_algorithm: 'TagLayout::InColumns',
            walking_algorithm: 'TagLayout::WalkWellsOfPlate',
            tag_group: tg,
            tag2_group: tg
          )
        end
      end

      desc 'Generate a mock PF-384 tag set if required'
      task pf384_tag_set: ['limber:dev:env_check', :environment] do
        next if TagLayoutTemplate.find_by(name: 'IDT for Illumina v1 - 384 Quadrant')

        tg =
          TagGroup.create!(name: 'IDT for Illumina v1 - MOCK') do |group|
            group.tags.build(
              OligoEnumerator.new(384).each_with_index.map { |oligo, map_id| { oligo:, map_id: map_id + 1 } }
            )
          end
        TagLayoutTemplate.create!(
          name: 'IDT for Illumina v1 - 384 Quadrant',
          direction_algorithm: 'TagLayout::InColumns',
          walking_algorithm: 'TagLayout::Quadrants',
          tag_group: tg,
          tag2_group: tg
        )
      end

      desc 'Add tag plates for GbS: dev only'
      task gbs_tag_plates: ['limber:dev:env_check', :environment, 'limber:dev:setup:gbs_tag_set'] do
        seeder = WorkingSetup::StandardSeeder.new([])
        ('A'..'D').each { |set| seeder.tag_plates(lot_type: 'Pre Stamped Tags - 384', template: "GbS Tag Set #{set}") }
      end

      desc 'Generate a mock WGS tag set if required'
      task wgs_tag_set: ['limber:dev:env_check', :environment] do
        ('A'..'D').each_with_index do |set, index|
          ["pWGS UDI tag layout v2 #{set}", "TS_pWGS#{set}_UDI96"].each_with_index do |template_name, idx|
            next if TagLayoutTemplate.find_by(name: template_name)

            tg =
              TagGroup.create!(name: "WGS Test #{idx} - #{set}") do |group|
                group.tags.build(
                  OligoEnumerator
                    .new(384, index * 384)
                    .each_with_index
                    .map { |oligo, map_id| { oligo:, map_id: map_id + 1 } }
                )
              end
            TagLayoutTemplate.create!(
              name: template_name,
              direction_algorithm: 'TagLayout::InColumns',
              walking_algorithm: 'TagLayout::WalkWellsOfPlate',
              tag_group: tg,
              tag2_group: tg
            )
          end
        end
      end

      desc 'Add tag plates for WGS: dev only'
      task wgs_tag_plates: ['limber:dev:env_check', :environment, 'limber:dev:setup:wgs_tag_set'] do
        seeder = WorkingSetup::StandardSeeder.new([])
        ('A'..'D').each do |set|
          ["pWGS UDI tag layout v2 #{set}", "TS_pWGS#{set}_UDI96"].each do |template_name|
            seeder.tag_plates(lot_type: 'Pre Stamped Tags', template: template_name)
          end
        end
      end
    end
  end
end
