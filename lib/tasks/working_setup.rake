namespace :working do
  task setup: :environment do
    ActiveRecord::Base.transaction do
  class PlateBarcode < ActiveResource::Base
   self.site = configatron.plate_barcode_service
   def self.create
     if @barcode.nil?
       @barcode = Plate.where.not(barcode:nil).where.not(barcode:"9999999").where('length(barcode)=7').
       order(barcode: :desc).first.try(:barcode).to_i
       @barcode = 9000000 if @barcode.zero? and not Plate.count.zero?
     end
     OpenStruct.new(barcode: (@barcode += 1))
   end
  end

   locations = {
    htp: Location.find_by_name('Illumina high throughput freezer'),
    ilc: Location.find_by_name('Library creation freezer')
   }

   program = Program.find_by_name('General')

   # Admin full barcode will be: Barcode.human_to_machine_barcode("ID99A")
   user = User.create!(login: 'admin',password: 'admin', swipecard_code: 'abcdef', barcode: 'ID99A')
   user.is_administrator
   faculty_sponsor = FacultySponsor.create!(name: 'Faculty Sponsor')

   project = Project.create!(name: 'A project',enforce_quotas: false, project_metadata_attributes: { project_cost_code: '1111', project_funding_model: 'Internal' })
   project.activate!
   study = Study.create!(name: 'A study',study_metadata_attributes: { faculty_sponsor: faculty_sponsor,data_release_study_type: DataReleaseStudyType.first, study_type: StudyType.first,study_description: 'A seeded test study',contaminated_human_dna: 'No',contains_human_dna: 'No',commercially_available: 'No', program_id: program.id })
   study.activate!
   study_b = Study.create!(name: 'B study',study_metadata_attributes: { faculty_sponsor: faculty_sponsor,data_release_study_type: DataReleaseStudyType.first, study_type: StudyType.first,study_description: 'A seeded test study',contaminated_human_dna: 'No',contains_human_dna: 'No',commercially_available: 'No', program_id: program.id })
   study_b.activate!

   user.is_owner(study)
   user.is_owner(study_b)

   SampleRegistrar.register!([sample_named('sample_a',study,user),sample_named('sample_b',study,user),sample_named('sample_c',study,user),sample_named('sample_d',study,user)])

   Purpose.find(2).create!.tap do |plate|
      plate.wells.each { |w| w.aliquots.create!(sample: Sample.create!(name: "sample_in_stock_well_#{w.map.description}", studies: [study])) }
      puts "Stock: #{plate.ean13_barcode}-#{plate.sanger_human_barcode}"
    end
    8.times do |i|
      Purpose.find_by_name('Cherrypicked').create!(location: locations[:htp]).tap do |plate|
        plate.wells.each { |w| w.aliquots.create!(sample: Sample.create!(name: "sample_in_cp#{i}_well_#{w.map.description}", studies: [study])) }
        puts "Cherrypicked: #{plate.ean13_barcode}-#{plate.sanger_human_barcode}"
      end
    end
    4.times do |i|
      Purpose.find_by_name('ILC Stock').create!(location: locations[:ilc]).tap do |plate|
        plate.wells.each { |w| w.aliquots.create!(sample: Sample.create!(name: "sample_in_ilc#{i}_well_#{w.map.description}", studies: [study])) }
        puts "ILC Stock: #{plate.ean13_barcode}-#{plate.sanger_human_barcode}"
      end
    end
    Purpose.find_by_name('ILB_STD_INPUT').create!.tap do |plate|
      plate.wells.each { |w| w.aliquots.create!(sample: Sample.create!(name: "sample_in_ilbstd_well_#{w.map.description}", studies: [study])) }
      puts "ILB-STD: #{plate.ean13_barcode}-#{plate.sanger_human_barcode}"
    end


    Robot.create!(name: 'Picking robot', location: 'In a lab').tap do |robot|
      robot.create_max_plates_property(value: 10)
    end

    Sample.all.each { |s| study_b.samples << s }

    BarcodePrinter.create!(name: 'g312bc2', barcode_printer_type: BarcodePrinterType.find_by_name('96 Well Plate'))
    BarcodePrinter.create!(name: 'g311bc2', barcode_printer_type: BarcodePrinterType.find_by_name('96 Well Plate'))
    BarcodePrinter.create!(name: 'g316bc',  barcode_printer_type: BarcodePrinterType.find_by_name('96 Well Plate'))
    BarcodePrinter.create!(name: 'g317bc',  barcode_printer_type: BarcodePrinterType.find_by_name('96 Well Plate'))
    BarcodePrinter.create!(name: 'g314bc',  barcode_printer_type: BarcodePrinterType.find_by_name('96 Well Plate'))
    BarcodePrinter.create!(name: 'g311bc1', barcode_printer_type: BarcodePrinterType.find_by_name('1D Tube'))

    Supplier.create!(name: 'Test Supplier')

    puts "Setting up tag plates..."
    lot = LotType.find_by_name('IDT Tags').lots.create!(
      lot_number: 'UATTaglot',
      template: TagLayoutTemplate.find_by_name('Sanger_168tags - 10 mer tags in columns ignoring pools (first oligo: ATCACGTT)'),
      user: user,
      received_at: DateTime.now
    )
   qcc = QcableCreator.create!(lot: lot,user: user,count: 30)
   qcc.qcables.each { |qcable| qcable.update_attributes!(state: 'available'); qcable.asset.update_attributes!(location: locations[:htp]);puts "Tag Plate: #{qcable.asset.ean13_barcode}" }

 end
 end
end

  def sample_named(name,study,user)
    {
        "sample_tube_attributes" => { "two_dimensional_barcode" => "" },
        "study" => study,
        "asset_group_name" => "asset_group",
        "sample_attributes" => {
          "name" => name,
          "sample_metadata_attributes" => {
            "replicate" => "",
            "organism" => "",
            "sample_strain_att" => "",
            "cell_type" => "",
            "immunoprecipitate" => "",
            "ethnicity" => "",
            "gc_content" => "Neutral",
            "compound" => "",
            "dna_source" => "Genomic",
            "supplier_plate_id" => "",
            "mother" => "",
            "sample_public_name" => "",
            "sample_common_name" => "",
            "sample_ebi_accession_number" => "",
            "disease_state" => "",
            "reference_genome_id" => "1",
            "organism_part" => "",
            "gender" => "",
            "country_of_origin" => "",
            "sample_taxon_id" => "",
            "genotype" => "",
            "growth_condition" => "",
            "subject" => "",
            "volume" => "",
            "treatment" => "",
            "geographical_region" => "",
            "sample_sra_hold" => "Hold",
            "rnai" => "", "time_point" => "",
            "sample_description" => "",
            "age" => "",
            "developmental_stage" => "",
            "dose" => "",
            "cohort" => "",
            "father" => "",
            "phenotype" => "",
            "disease" => ""
          }
        },
        "user" => user,
        "ignore" => "0"
      }
  end
