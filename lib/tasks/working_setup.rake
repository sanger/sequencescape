namespace :working do
  task setup: :environment do
    ActiveRecord::Base.transaction do
  class PlateBarcode < ActiveResource::Base
   self.site = configatron.plate_barcode_service
   def self.create
     if @barcode.nil?
       @barcode = Plate.where.not(barcode: nil).where.not(barcode: '9999999').where('length(barcode)=7')
                       .order(barcode: :desc).first.try(:barcode).to_i
       @barcode = 9000000 if @barcode.zero? and not Plate.count.zero?
     end
     OpenStruct.new(barcode: (@barcode += 1))
   end
  end

  class WorkingSetupSeeder
    attr_reader :locations, :program

    def initialize
      @locations = {
        htp: Location.find_by(name: 'Illumina high throughput freezer'),
        ilc: Location.find_by(name: 'Library creation freezer')
       }
      @program = Program.find_by(name: 'General')
    end

    def seed
       create_project('A project')
       study   = create_study('A study')
       study_b = create_study('B study')

       SampleRegistrar.register!([sample_named('sample_a', study), sample_named('sample_b', study), sample_named('sample_c', study), sample_named('sample_d', study)])

       Purpose.find(2).create!.tap do |plate|
          plate.wells.each { |w| w.aliquots.create!(sample: Sample.create!(name: "sample_in_stock_well_#{w.map.description}", studies: [study])) }
          puts "Stock: #{plate.ean13_barcode}-#{plate.sanger_human_barcode}"
       end
        8.times do |i|
          Purpose.find_by(name: 'Cherrypicked').create!(location: locations[:htp]).tap do |plate|
            plate.wells.each { |w| w.aliquots.create!(sample: Sample.create!(name: "sample_in_cp#{i}_well_#{w.map.description}", studies: [study])) }
            puts "Cherrypicked: #{plate.ean13_barcode}-#{plate.sanger_human_barcode}"
          end
        end
        4.times do |i|
          Purpose.find_by(name: 'ILC Stock').create!(location: locations[:ilc]).tap do |plate|
            plate.wells.each { |w| w.aliquots.create!(sample: Sample.create!(name: "sample_in_ilc#{i}_well_#{w.map.description}", studies: [study])) }
            puts "ILC Stock: #{plate.ean13_barcode}-#{plate.sanger_human_barcode}"
          end
        end

        Robot.create!(name: 'Picking robot', location: 'In a lab').tap do |robot|
          robot.create_max_plates_property(value: 10)
        end

        Sample.all.each { |s| study_b.samples << s }

        BarcodePrinter.create!(name: 'g312bc2', barcode_printer_type: BarcodePrinterType.find_by(name: '96 Well Plate'))
        BarcodePrinter.create!(name: 'g311bc2', barcode_printer_type: BarcodePrinterType.find_by(name: '96 Well Plate'))
        BarcodePrinter.create!(name: 'g316bc',  barcode_printer_type: BarcodePrinterType.find_by(name: '96 Well Plate'))
        BarcodePrinter.create!(name: 'g317bc',  barcode_printer_type: BarcodePrinterType.find_by(name: '96 Well Plate'))
        BarcodePrinter.create!(name: 'g314bc',  barcode_printer_type: BarcodePrinterType.find_by(name: '96 Well Plate'))
        BarcodePrinter.create!(name: 'g311bc1', barcode_printer_type: BarcodePrinterType.find_by(name: '1D Tube'))

        Supplier.create!(name: 'Test Supplier')

        puts 'Setting up tag plates...'
        lot = LotType.find_by(name: 'IDT Tags').lots.create!(
          lot_number: 'UATTaglot',
          template: TagLayoutTemplate.find_by(name: 'Sanger_168tags - 10 mer tags in columns ignoring pools (first oligo: ATCACGTT)'),
          user: user,
          received_at: DateTime.now
        )
       qcc = QcableCreator.create!(lot: lot, user: user, count: 30)
       qcc.qcables.each { |qcable| qcable.update_attributes!(state: 'available'); qcable.asset.update_attributes!(location: locations[:htp]); puts "Tag Plate: #{qcable.asset.ean13_barcode}" }
    end

    private

    def user
      @user ||= create_or_find_user
    end

    def create_or_find_user
      existing = User.find_by(login: 'admin')
      return existing if existing
      User.create!(login: 'admin', password: 'admin', swipecard_code: 'abcdef', barcode: 'ID99A') do |user|
        user.is_administrator
      end
    end

    def faculty_sponsor
      @faculty_sponsor ||= FacultySponsor.find_by(name: 'Faculty Sponsor') || FacultySponsor.create!(name: 'Faculty Sponsor')
    end

    def create_project(name)
      existing = Project.find_by(name: name)
      return existing if existing
      Project.create!(
        name: name,
        enforce_quotas: false,
        approved: true,
        project_metadata_attributes: {
          project_cost_code: '1111',
          project_funding_model: 'Internal'
        }
      ) do |project|
        project.activate!
      end
    end

    def create_study(name)
      existing = Study.find_by(name: name)
      return existing if existing
      Study.create!(
        name: name,
        study_metadata_attributes: {
          data_access_group: 'dag',
          study_type: StudyType.first,
          faculty_sponsor: faculty_sponsor,
          data_release_study_type: DataReleaseStudyType.first,
          study_description: 'A seeded test study',
          contaminated_human_dna: 'No',
          contains_human_dna: 'No',
          commercially_available: 'No',
          program_id: program.id
        }
      ) do |study|
        study.activate!
        user.is_owner(study)
      end
    end

    def sample_named(name, study)
      {
          'sample_tube_attributes' => { 'two_dimensional_barcode' => '' },
          'study' => study,
          'asset_group_name' => 'asset_group',
          'sample_attributes' => {
            'name' => name,
            'sample_metadata_attributes' => {
              'replicate' => '',
              'organism' => '',
              'sample_strain_att' => '',
              'cell_type' => '',
              'immunoprecipitate' => '',
              'ethnicity' => '',
              'gc_content' => 'Neutral',
              'compound' => '',
              'dna_source' => 'Genomic',
              'supplier_plate_id' => '',
              'mother' => '',
              'sample_public_name' => '',
              'sample_common_name' => '',
              'sample_ebi_accession_number' => '',
              'disease_state' => '',
              'reference_genome_id' => '1',
              'organism_part' => '',
              'gender' => '',
              'country_of_origin' => '',
              'sample_taxon_id' => '',
              'genotype' => '',
              'growth_condition' => '',
              'subject' => '',
              'volume' => '',
              'treatment' => '',
              'geographical_region' => '',
              'sample_sra_hold' => 'Hold',
              'rnai' => '', 'time_point' => '',
              'sample_description' => '',
              'age' => '',
              'developmental_stage' => '',
              'dose' => '',
              'cohort' => '',
              'father' => '',
              'phenotype' => '',
              'disease' => ''
            }
          },
          'user' => user,
          'ignore' => '0'
        }
    end
  end

  WorkingSetupSeeder.new.seed
    end
  end
end
