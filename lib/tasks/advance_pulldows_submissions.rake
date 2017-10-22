# This ensures that the test database is seeded with the correct data before any tests
# are run.  The great thing about this is that it happens before *all* tests and features,
# or just before the specific one requested.
namespace :benchmark do
  task setup: :environment do
    plate_count = ENV['PLATECOUNT'] || 25
    $stderr.puts 'Building WGS submissions ...'

    # Printers we need
    BarcodePrinterType.find(1).barcode_printers.create!(name: 'h126bc')  # 1D tube printer
    BarcodePrinterType.find(2).barcode_printers.create!(name: 'k115bc2') # 96 well printer
    BarcodePrinterType.find(2).barcode_printers.create!(name: 'h137bc')  # 96 well printer
    BarcodePrinterType.find(3).barcode_printers.create!(name: 'd304bc')  # 384 well printer

    # Rubbish data we need
    study       = Study.new(name: 'Pulldown study', state: 'active').tap { |t| t.save(validate: false) }
    project     = Project.create!(name: 'Pulldown project', enforce_quotas: false, project_metadata_attributes: { project_cost_code: '1111' })
    user        = User.create!(login: 'Pulldown user', password: 'foobar', swipecard_code: 'abcdef', workflow_id: 1).tap do |u|
      u.roles.create!(name: 'administrator')
    end

    # Plate that can be submitted for each pipeline
    stock_plate = PlatePurpose.find(2).create!.tap do |plate|
      plate.wells.each { |w| w.aliquots.create!(sample: Sample.create!(name: "sample_in_stock_well_#{w.map.description}")) }
    end

    [
      'Pulldown WGS'
    ].each do |pipeline|
      $stderr.puts pipeline.to_s

      $stderr.puts "Building #{plate_count} Plates"
      plate_count.times do
        $stderr.print '.'
        SubmissionTemplate.find_by(name: "Cherrypick for pulldown - #{pipeline} - HiSeq Paired end sequencing").create_with_submission!(
          user: user, study: study, project: project,
          assets: stock_plate.wells,
          request_options: {
            read_length: 100,
            bait_library_name: BaitLibrary.first.name
          }
        )
      end
    end

    $stderr.puts "\tBuilding submission request graphs. This might take some time..."
    LinearSubmission.all.each(&:build_request_graph!)

    $stderr.puts 'Advancing submissions'
    Submission.all.each do |sub|
      $stderr.puts 'Making Plate'
      plate = PlatePurpose.find_by(name: 'WGS stock DNA').create!(:without_wells)
      $stderr.puts 'Passing Requests'
      sub.requests.each do |r|
        $stderr.print '.'
        next unless r.is_a?(CherrypickRequest)
        next if r.passed?
        r.start!
        r.pass!
        r.target_asset.update_attributes!(container: plate)
        r.target_asset.update_attributes!(map_id: r.asset.map_id)
        r.save!
      end
      $stderr.puts ''
    end
  end
end
