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
  BarcodePrinterType.find(3).barcode_printers.create!(:name => 'd304bc')  # 384 well printer

  # Tag layout templates
  TagLayoutTemplate.create!(
    :name => 'Pulldown test 96 template',
    :tag_group => TagGroup.create!(:name => 'Pulldown 96 tags').tap { |g| g.tags << (1..96).map { |i| Tag.create!(:map_id => (g.id*100)+i, :oligo => "ACGT#{i}") } },
    :layout_class_name => 'TagLayout::InColumns'
  )
  TagLayoutTemplate.create!(
    :name => 'Pulldown test 8 template (in columns)',
    :tag_group => TagGroup.create!(:name => 'Pulldown 8 tags').tap { |g| g.tags << (1..8).map { |i| Tag.create!(:map_id => (g.id*100)+i, :oligo => "ACGT#{i}") } },
    :layout_class_name => 'TagLayout::InColumns'
  )

  # Rubbish data we need
  study       = Study.new(:name => 'Pulldown study').tap { |t| t.save_without_validation }
  project     = Project.create!(:name => 'Pulldown project', :enforce_quotas => false, :project_metadata_attributes => { :project_cost_code => '1111' })
  user        = User.create!(:login => 'Pulldown user', :password => 'foobar').tap { |u| u.roles.create!(:name => 'administrator') }

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

    SubmissionTemplate.find_by_name("Cherrypick for pulldown - #{pipeline} - HiSeq Paired end sequencing").create!(
      :user => user, :study => study, :project => project,
      :assets => stock_plate.wells,
      :request_options => {
        :read_length => 100,
        :fragment_size_required_from => 100, :fragment_size_required_to => 200,
        :bait_library_name => BaitLibrary.first.name
      }
    ).built!
  end

  $stderr.puts "\tBuilding submission request graphs ..."
  Delayed::Worker.new.work_off(10)

  $stderr.puts "You probably want to remove this file: #{__FILE__}"
end
