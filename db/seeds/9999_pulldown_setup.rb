if ENV['PULLDOWN']||ENV['ILLUMINAB']
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

chosen_pipeline = ENV['PULLDOWN'] ? 'Pulldown' : 'Illumina b'

options_hash = {
  'Pulldown' => {
    :pipelines_array => [
      'Pulldown WGS',
      'Pulldown SC',
      'Pulldown ISC'
    ],

    :submission_template_name => lambda {|pipeline| "Cherrypick for pulldown - #{pipeline} - HiSeq Paired end sequencing"}


  },
  'Illumina b' => {
    :pipelines_array => [
      'Illumina-B STD'
    ],

    :submission_template_name => lambda {|_| 'Illumina-B - Cherrypicked - Multiplexed WGS - HiSeq Paired end sequencing' }

  }
}
  ActiveRecord::Base.transaction do
    $stderr.puts "Building submissions for all of the #{chosen_pipeline} pipelines ..."

    # Printers we need
    BarcodePrinterType.find(1).barcode_printers.create!(:name => 'h126bc')  # 1D tube printer
    BarcodePrinterType.find(2).barcode_printers.create!(:name => 'k115bc2') # 96 well printer
    BarcodePrinterType.find(2).barcode_printers.create!(:name => 'h137bc')  # 96 well printer
    BarcodePrinterType.find(2).barcode_printers.create!(:name => 'd304bc')  # 96 well printer

    # Tag layout templates
    TagLayoutTemplate.create!(
      :name => '#{chosen_pipeline} test 96 template',
      :tag_group => TagGroup.create!(:name => '#{chosen_pipeline} 96 tags').tap { |g| g.tags << (1..96).map { |i| Tag.create!(:map_id => (g.id*100)+i, :oligo => "ACGT#{i}") } },
      :direction_algorithm => 'TagLayout::InColumns',
      :walking_algorithm => 'TagLayout::WalkWellsOfPlate'
    )
    TagLayoutTemplate.create!(
      :name => '#{chosen_pipeline} test 8 template (in columns)',
      :tag_group => TagGroup.create!(:name => 'Pulldown 8 tags').tap { |g| g.tags << (1..8).map { |i| Tag.create!(:map_id => (g.id*100)+i, :oligo => "ACGT#{i}") } },
      :direction_algorithm => 'TagLayout::InColumns',
      :walking_algorithm => 'TagLayout::WalkWellsByPools'
    )

    # Rubbish data we need
    study       = Study.new(:name => "#{chosen_pipeline} study", :state => 'active').tap { |t| t.save_without_validation }
    project     = Project.create!(:name => "#{chosen_pipeline} project", :enforce_quotas => false, :project_metadata_attributes => { :project_cost_code => '1111' })
    user        = User.create!(:login => "testuser", :password => 'testuser', :swipecard_code => 'abcdef', :workflow_id => 1).tap do |u|
      u.roles.create!(:name => 'administrator')
    end

    Robot.create!(:name => 'Picking robot', :location => 'In a lab').tap do |robot|
      robot.create_max_plates_property(:value => 10)
    end

    # Plate that can be submitted for each pipeline
    stock_plate = PlatePurpose.find(2).create!.tap do |plate|
      plate.wells.each { |w| w.aliquots.create!(:sample => Sample.create!(:name => "sample_in_stock_well_#{w.map.description}")) }
    end

    options_hash[chosen_pipeline][:pipelines_array].each do |pipeline|
      template_name = options_hash[chosen_pipeline][:submission_template_name].call(pipeline)

      $stderr.puts "\t#{pipeline}"

      [ 1, 2, 4, 8, 12, 48, 96 ].each do |group_size|
        $stderr.puts "\t\t#{group_size}-plex"
        stock_plate.wells.in_column_major_order.in_groups_of(group_size).each do |wells_to_submit|
          SubmissionTemplate.find_by_name(template_name).create_with_submission!(
            :user => user, :study => study, :project => project,
            :assets => wells_to_submit.compact,
            :request_options => {
              :read_length => 100,
              :bait_library_name => BaitLibrary.first.name
            }
          )
        end
      end
    end

    $stderr.puts "\tBuilding submission request graphs. This might take some time..."
    LinearSubmission.all.each(&:build_request_graph!)

    $stderr.puts "Fudging 7 additional HiSeq requests so that they are available"
    LinearSubmission.new(:study => Study.first, :request_types => [ 8 ], :project => Project.first, :user => User.first, :workflow_id => 1).save_without_validation

    submission = LinearSubmission.last.create_submission

    (1..7).each do |i|
      tube    = Tube::Purpose.standard_mx_tube.create!(:location => Location.find(2)).tap { |t| t.aliquots.create!(:sample => Sample.create!(:name => "fudge_#{i}")) }
      request = RequestType.find(8).create!(:asset => tube, :study => Study.first, :submission => submission, :request_metadata_attributes => { :fragment_size_required_from => 100, :fragment_size_required_to => 200, :read_length => 100 })
    end

    $stderr.puts "You probably want to remove this file: #{__FILE__}"
  end
end
