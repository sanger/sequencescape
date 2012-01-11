if ENV['PULLDOWN']
  # This is a temporary file because I got tired of typing it every time I wanted to test the Pulldown pipelines!
  class PlateBarcode
    def self.create
      Object.new.tap do |o|
        def o.barcode
          rand(0x10000)
        end
      end
    end
  end

  ActiveRecord::Base.transaction do
    $stderr.puts "Building submissions for all of the pulldown pipelines ..."

    # Printers we need
    BarcodePrinterType.find(1).barcode_printers.create!(:name => 'h126bc')  # 1D tube printer
    BarcodePrinterType.find(2).barcode_printers.create!(:name => 'k115bc2') # 96 well printer
    BarcodePrinterType.find(2).barcode_printers.create!(:name => 'h137bc')  # 96 well printer
    BarcodePrinterType.find(3).barcode_printers.create!(:name => 'd304bc')  # 384 well printer

    # Tag layout templates
    TagLayoutTemplate.create!(
      :name => 'Pulldown test 96 template',
      :tag_group => TagGroup.create!(:name => 'Pulldown 96 tags').tap { |g| g.tags << (1..96).map { |i| Tag.create!(:map_id => (g.id*100)+i, :oligo => "ACGT#{i}") } },
      :direction_algorithm => 'TagLayout::InColumns',
      :walking_algorithm => 'TagLayout::WalkWellsOfPlate'
    )
    TagLayoutTemplate.create!(
      :name => 'Pulldown test 8 template (in columns)',
      :tag_group => TagGroup.create!(:name => 'Pulldown 8 tags').tap { |g| g.tags << (1..8).map { |i| Tag.create!(:map_id => (g.id*100)+i, :oligo => "ACGT#{i}") } },
      :direction_algorithm => 'TagLayout::InColumns',
      :walking_algorithm => 'TagLayout::WalkWellsByPools'
    )

    # Rubbish data we need
    study       = Study.new(:name => 'Pulldown study', :state => 'active').tap { |t| t.save_without_validation }
    project     = Project.create!(:name => 'Pulldown project', :enforce_quotas => false, :project_metadata_attributes => { :project_cost_code => '1111' })
    user        = User.create!(:login => 'Pulldown user', :password => 'foobar', :swipecard_code => 'abcdef', :workflow_id => 1).tap do |u|
      u.roles.create!(:name => 'administrator')
    end

    # Plate that can be submitted for each pipeline
    stock_plate = PlatePurpose.find(2).create!.tap do |plate|
      plate.wells.each { |w| w.aliquots.create!(:sample => Sample.create!(:name => "sample_in_stock_well_#{w.map.description}")) }
    end

    [
      'Pulldown WGS',
      'Pulldown SC',
      'Pulldown ISC'
    ].each do |pipeline|
      $stderr.puts "\t#{pipeline}"

      $stderr.puts "\t\tFull plate"
      SubmissionTemplate.find_by_name("Cherrypick for pulldown - #{pipeline} - HiSeq Paired end sequencing").create_with_submission!(
        :user => user, :study => study, :project => project,
        :assets => stock_plate.wells,
        :request_options => {
          :read_length => 100,
          :bait_library_name => BaitLibrary.first.name
        }
      )

      # Submit the plate in two halves
      $stderr.puts "\t\tTwo halves"
      SubmissionTemplate.find_by_name("Cherrypick for pulldown - #{pipeline} - HiSeq Paired end sequencing").create_with_submission!(
        :user => user, :study => study, :project => project,
        :assets => stock_plate.wells.slice(0, 48),
        :request_options => {
          :read_length => 100,
          :bait_library_name => BaitLibrary.first.name
        }
      )

      SubmissionTemplate.find_by_name("Cherrypick for pulldown - #{pipeline} - HiSeq Paired end sequencing").create_with_submission!(
        :user => user, :study => study, :project => project,
        :assets => stock_plate.wells.slice(48, 96),
        :request_options => {
          :read_length => 100,
          :bait_library_name => BaitLibrary.first.name
        }
      )

      # Submit the plate in columns
      (1..12).each do |column|
        $stderr.puts "\t\tColumn #{column}"
        wells_to_submit = []
        stock_plate.wells.walk_in_column_major_order do |well, _|
          wells_to_submit << well if well.map.description =~ /^[A-H]#{column}$/
        end

        SubmissionTemplate.find_by_name("Cherrypick for pulldown - #{pipeline} - HiSeq Paired end sequencing").create_with_submission!(
          :user => user, :study => study, :project => project,
          :assets => wells_to_submit,
          :request_options => {
            :read_length => 100,
            :bait_library_name => BaitLibrary.first.name
          }
        )
      end
    end

    $stderr.puts "\tBuilding submission request graphs. This might take some time..."
    LinearSubmission.all.each(&:build_request_graph!)

    $stderr.puts "Fudging 7 additional HiSeq requests so that they are available"
    LinearSubmission.new(:study => Study.first, :request_types => [ 8 ], :project => Project.first, :user => User.first, :workflow_id => 1).save_without_validation

    submission = LinearSubmission.last.create_submission

    (1..7).each do |i|
      tube    = MultiplexedLibraryTube.create!(:location => Location.find(2)).tap { |t| t.aliquots.create!(:sample => Sample.create!(:name => "fudge_#{i}")) }
      request = RequestType.find(8).create!(:asset => tube, :study => Study.first, :submission => submission, :request_metadata_attributes => { :fragment_size_required_from => 100, :fragment_size_required_to => 200, :read_length => 100 })
    end

    $stderr.puts "You probably want to remove this file: #{__FILE__}"
  end
end
