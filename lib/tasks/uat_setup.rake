require_relative 'uat_filters'
namespace :uat do
  desc 'Establishes an environment for UAT...'
  # Built from this task as the seeds don't guarantee an accurate reflection of some key production tables
  # Plus there a whole load of useful things in the database that nonetheless don't belong in seeds
  task :setup, [:db_file, :expected_env] => :environment do |_t, args|
    class PlateBarcode < ActiveResource::Base
     self.site = configatron.plate_barcode_service
     def self.create
       if @barcode.nil?
         @barcode = Plate.first(
           conditions: 'barcode is not null and barcode!="9999999" and length(barcode)=7',
           order: 'barcode desc'
         ).try(:barcode).to_i

         @barcode = 9000000 if @barcode.zero? and not Plate.count.zero?
       end
       OpenStruct.new(barcode: (@barcode += 1))
     end
    end

    def sample_named(name, study, user)
      {
          'sample_tube_attributes' => { 'two_dimensional_barcode' => '' },
          'study' => study,
          'asset_group_name' => "asset_group_#{study.id}",
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
              'sample_ebi_accession_number' => 'XXX',
              'disease_state' => '',
              'reference_genome_id' => '1',
              'organism_part' => '',
              'gender' => '',
              'country_of_origin' => '',
              'sample_taxon_id' => '',
              'genotype' => '',
              'growth_condition' => '',
              'subject' => '',
              'volume' => '100',
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

    if args[:expected_env].nil? || args[:db_file].nil?
            raise StandardError, <<-MESSAGE
**********************************************************************************************************
****************************************** NO SETTINGS PROVIDED ******************************************

Please specify a source gzipped database and an expected environment.

For example: rake uat:setup[/User/example/dump.gz,development]

**********************************************************************************************************
**********************************************************************************************************
      MESSAGE

    elsif Rails.env.downcase.to_sym == :production

      raise StandardError, <<-MESSAGE
**********************************************************************************************************
***************************** CAN NOT ESTABLISH UAT ENVIRONMENT IN PRODUTION *****************************

You are attempting to establish a UAT environment in the production database. This action is destructive
and should not be undertaken under any circumstances. If you were actually intending to do this STOP and
do not attempt to bypass this restriction.

**********************************************************************************************************
**********************************************************************************************************
      MESSAGE

    elsif args[:expected_env].downcase.to_sym != Rails.env.downcase.to_sym

      raise StandardError, <<-MESSAGE
**********************************************************************************************************
****************************** ATTEMPTING TO CHANGE UNEXPECTED ENVIRONMENT! ******************************

You are currently in the '#{Rails.env.downcase}' environment, but specified '#{args[:expected_env]}'.
Setting up a UAT environment is a destructive action so this check is performed to reduce the risk of
accidently deploying in the wrong environment. Please double check which environment you are supposed
to be deploying to before continuing.

You can specify an expected environment like so: rake uat:setup[file_path,environment]

**********************************************************************************************************
**********************************************************************************************************
      MESSAGE

      elsif args[:expected_env].downcase.to_sym == Rails.env.downcase.to_sym && Rails.env.downcase.to_sym != :production

      # Kept tables
      kept = %w(
        asset_shapes bait_libraries bait_library_layouts bait_library_suppliers bait_library_types
        barcode_prefixes barcode_printer_types barcode_printers budget_divisions controls
        custom_texts data_release_study_types descriptors families lab_interface_workflows
        library_types library_types_request_types locations lot_types maps order_roles
        pipeline_request_information_types pipelines pipelines_request_types plate_creator_purposes
        plate_creators plate_purpose_relationships plate_purposes product_lines project_managers
        reference_genomes request_information_types request_type_plate_purposes request_type_validators
        request_types robot_properties robots roles roles_users sample_manifest_templates schema_migrations
        searches study_relation_types study_relations study_types subclass_attributes submission_templates
        submission_workflows suppliers tag_groups tag_layout_templates tags task_request_types
        tasks transfer_templates users
      )

      db_file = args[:db_file]
      raise StandardError, 'Must specify a production dump path e.g rake uat:setup[file_path,environment]' if db_file.nil?
      raise StandardError, "Could not find #{db_file}" unless File.exist?(db_file)

      puts 'Importing production information...'
      `pv -per #{db_file} | gunzip -c | ruby ./lib/tasks/sql_filter.rb | ./script/dbconsole -p`
      puts 'Production imported.'

      puts 'Resetting primary key counters'
      UATFilters::FILTERED_TABLES.each do |table|
        ActiveRecord::Base.connection.execute("ALTER TABLE #{table} AUTO_INCREMENT = 1;")
      end

      puts 'Seeding!'

      puts 'Creating basic template...'

      PlateTemplate.create!(name: 'Empty Template')

      puts 'Setting up projects...'
      Project.create!(
        name: 'UAT project A',
        enforce_quotas: true,
        approved: true,
        state: 'active',
        project_metadata_attributes: {
          project_cost_code: 'UATA',
          project_funding_model: 'Internal',
          project_manager_id: ProjectManager.find_or_create_by(name: 'UAT manager').id,
          budget_division_id: BudgetDivision.find_or_create_by(name: 'UAT internal division').id
        }
      )
      Project.create!(
        name: 'UAT project B',
        enforce_quotas: true,
        approved: true,
        state: 'active',
        project_metadata_attributes: {
          project_cost_code: 'UATA',
          project_funding_model: 'External',
          project_manager_id: ProjectManager.find_or_create_by(name: 'UAT manager').id,
          budget_division_id: BudgetDivision.find_or_create_by(name: 'UAT external division').id
        }
      )

      puts 'Faking a sponsor...'

      FacultySponsor.create!(name: 'UAT Sponsor')

      puts 'Setting up studies...'

      Study.create!(
        name: 'UAT study A',
        study_metadata_attributes: {
          study_ebi_accession_number: 'YYYY',
          study_type: StudyType.find_by(name: 'Exome Sequencing'),
          faculty_sponsor: FacultySponsor.last,
          data_release_study_type: DataReleaseStudyType.find_by(name: 'genomic sequencing'),
          study_description: 'A seeded test study',
          contaminated_human_dna: 'No',
          contains_human_dna: 'No',
          commercially_available: 'No'
        }
      ).activate!

      Study.create!(
        name: 'UAT study B',
        study_metadata_attributes: {
          study_ebi_accession_number: 'YYYY',
          study_type: StudyType.find_by(name: 'Exome Sequencing'),
          faculty_sponsor: FacultySponsor.last,
          data_release_study_type: DataReleaseStudyType.find_by(name: 'genomic sequencing'),
          study_description: 'A seeded test study',
          contaminated_human_dna: 'No',
          contains_human_dna: 'No',
          commercially_available: 'No'
        }
      ).activate!

      Study.create!(
        name: 'UAT study C',
        study_metadata_attributes: {
          study_ebi_accession_number: 'YYYY',
          study_type: StudyType.find_by(name: 'Exome Sequencing'),
          faculty_sponsor: FacultySponsor.last,
          data_release_study_type: DataReleaseStudyType.find_by(name: 'genomic sequencing'),
          study_description: 'A seeded test study with mock human data',
          contaminated_human_dna: 'No',
          contains_human_dna: 'Yes',
          commercially_available: 'No'
        }
      ).activate!

      puts 'Adding UAT user'

      user = User.create!(login: 'UAT user', swipecard_code: 'uat_test', workflow_id: 1).tap do |u|
        u.roles.create!(name: 'administrator')
      end

      puts 'Registering samples/assets'

      Study.find_each do |study|
        print '.'
        SampleRegistrar.register!((1..96).map { |i| sample_named("sample_#{study.id}_#{i}", study, user) })
        print '.'
        stock = Purpose.find(2).create!(barcode: (10 * study.id)).tap do |plate|
          plate.wells.each { |w| w.aliquots.create!(
            sample: Sample.create!(
              name: "sample_in_#{w.plate.sanger_human_barcode}#{w.map.description}",
              studies: [study],
              sample_metadata_attributes: {
                sample_ebi_accession_number: 'XXX',
                sample_taxon_id: 9603 + study.id
              }
            ),
            study: study
          )}
          puts "Stock: #{plate.ean13_barcode}-#{plate.sanger_human_barcode}"
        end
        (1..4).each do |i|
          child = Purpose.find_by(name: 'Cherrypicked').create!(barcode: i + (10 * study.id), location: Location.find_by(name: 'Illumina high throughput freezer'))
          child.wells.each { |w| w.aliquots << stock.wells.located_at(w.map_description).first.aliquots.first.clone }
          puts "Cherrypicked: #{child.ean13_barcode}-#{child.sanger_human_barcode}"
        end
        (1..4).each do |i|
          child = Purpose.find_by(name: 'ILC Stock').create!(barcode: i + 4 + (10 * study.id), location: Location.find_by(name: 'Illumina high throughput freezer'))
          child.wells.each { |w| w.aliquots << stock.wells.located_at(w.map_description).first.aliquots.first.clone }
          puts "ILC Stock: #{child.ean13_barcode}-#{child.sanger_human_barcode}"
        end
      end
      user = User.last
      puts 'Setting up tag plates...'
      lot = LotType.find_by(name: 'IDT Tags').lots.create!(
        lot_number: 'UATTaglot',
        template: TagLayoutTemplate.find_by(name: 'Sanger_168tags - 10 mer tags in columns ignoring pools (first oligo: ATCACGTT)'),
        user: user,
        received_at: DateTime.now
      )
     qcc = QcableCreator.create!(lot: lot, user: user, count: 30)
     qcc.qcables.each { |qcable| qcable.update_attributes!(state: 'available'); puts "Tag Plate: #{qcable.asset.ean13_barcode}" }

    else
      # We should never be hitting here
      raise StandardError, 'The task has found itself in an unexpected state.'
    end
  end
end
