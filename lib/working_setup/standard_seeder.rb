# frozen_string_literal: true

# This is part of a rake task
# rubocop:disable Rails/Output
module WorkingSetup
  # Class WorkingSetup::WorkingSetupSeeder provides tools to assist
  # with automatic creation of plates etc. for development
  #
  # @author Genome Research Ltd.
  #
  class StandardSeeder
    attr_reader :program

    def initialize(purposes = [])
      @program = Program.find_or_create_by!(name: 'General')
      @purposes = purposes
    end

    def study
      @study ||= create_study('A study')
    end

    def study_b
      @study_b ||= create_study('B study')
    end

    def phi_x_study
      create_study(PhiX.configuration[:default_study_option])
    end

    def project
      @project ||= create_project('A project')
    end

    def supplier
      Supplier.find_or_create_by!(name: 'Test Supplier')
    end

    def seed
      Sample.find_each { |s| study_b.samples << s }
      create_purposes

      Robot
        .create!(name: 'Picking robot', location: 'In a lab')
        .tap { |robot| robot.create_max_plates_property(value: 10) }
    end

    def plates_of_purpose(name, number) # rubocop:todo Metrics/AbcSize
      purpose = Purpose.find_by!(name:)
      number.times do
        purpose.create!.tap do |plate|
          plate.wells.each do |w|
            w.aliquots.create!(
              sample:
                Sample.create!(name: "sample_#{plate.human_barcode}_#{w.map.description}", studies: [study, study_b])
            )
          end
          puts "#{name}: #{plate.ean13_barcode}-#{plate.human_barcode}"
        end
      end
    end

    # rubocop:todo Metrics/AbcSize
    def tag_plates( # rubocop:todo Metrics/MethodLength
      lot_type: 'IDT Tags',
      template: 'Sanger_168tags - 10 mer tags in columns ignoring pools (first oligo: ATCACGTT)',
      size: 30
    )
      puts 'Setting up tag plates...'
      lot =
        LotType
          .find_by!(name: lot_type)
          .lots
          .create!(
            lot_number: Time.current.to_i.to_s,
            template: TagLayoutTemplate.find_by!(name: template),
            user: user,
            received_at: Time.current
          )
      qcc = QcableCreator.create!(lot: lot, user: user, count: size)
      qcc.qcables.each do |qcable|
        qcable.update!(state: 'available')
        puts "Tag Plate: #{qcable.asset.ean13_barcode}"
      end
    end

    # rubocop:enable Metrics/AbcSize

    def create_purposes
      @purposes.each { |options| plates_of_purpose(*options) }
    end

    def user
      @user ||= create_or_find_user
    end

    private

    def create_or_find_user
      existing = User.find_by(login: 'admin')
      return existing if existing

      User.create!(login: 'admin', password: 'admin', swipecard_code: 'abcdef', barcode: 'ID99A').tap(
        &:grant_administrator
      )
    end

    def faculty_sponsor
      @faculty_sponsor ||= UatActions::StaticRecords.faculty_sponsor
    end

    def create_project(name)
      existing = Project.find_by(name:)
      return existing if existing

      Project.create!(
        name: name,
        enforce_quotas: false,
        approved: true,
        project_metadata_attributes: {
          project_cost_code: '1111',
          project_funding_model: 'Internal'
        },
        &:activate!
      )
    end

    def create_study(name)
      existing = Study.find_by(name:)
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
          program_id: program.id,
          ebi_library_strategy: 'WGS',
          ebi_library_selection: 'PCR',
          ebi_library_source: 'GENOMIC'
        }
      ) do |study|
        study.activate!
        user.grant_owner(study)
      end
    end

    def sample_named(name, study)
      {
        'sample_tube_attributes' => {
          'two_dimensional_barcode' => ''
        },
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
            'rnai' => '',
            'time_point' => '',
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
end
# This is part of a rake task
# rubocop:enable Rails/Output
