# This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and authorship of this file.
# Copyright (C) 2007-2011,2012,2013,2014,2015,2016 Genome Research Ltd.

require 'factory_girl'

FactoryGirl.define do
  factory :api_application do
    sequence(:name) { |i| "App #{i}" }
    contact 'test@example.com'
    privilege 'full'
  end

  factory :comment  do
    description 'It is okay I guess'
    association(:commentable, factory: :asset)
  end

  factory :aliquot, aliases: [:tagged_aliquot, :dual_tagged_aliquot] do
    sample
    study
    project
    tag
    tag2
    receptacle

    factory :untagged_aliquot do
      tag  nil
      tag2 nil
    end

    factory :single_tagged_aliquot do
      tag
      tag2 nil
    end
  end

  factory :aliquot_receptacle, class: Aliquot::Receptacle, aliases: [:receptacle] do
  end

  factory :event do
    family          ''
    content         ''
    message         ''
    eventful_type   ''
    eventful_id     ''
    type            'Event'
  end

  factory :item do
    name               { |_a| generate :item_name }
    sequence(:version) { |a| a }
    workflow           { |workflow| workflow.association(:submission_workflow) }
    count              nil
    closed             false
  end

  factory :study_type do
    name  { generate :study_type_name }
  end

  factory :data_release_study_type do
    name  { generate :data_release_study_type_name }
  end

  factory :study_metadata, class: Study::Metadata do
    faculty_sponsor
    study_description           'Some study on something'
    program                     { Program.find_or_create_by(name: 'General') }
    contaminated_human_dna      'No'
    contains_human_dna          'No'
    commercially_available      'No'
    # Study type is implemented poorly. But I'm in the middle of the rails 4
    # upgrade at the moment, so I need to get things working before I change them.
    study_type                  { StudyType.find_or_create_by(name: 'Not specified') }
    # This is probably a bit grim as well
    data_release_study_type     { DataReleaseStudyType.find_or_create_by(name: 'genomic sequencing') }
    reference_genome            { ReferenceGenome.find_by!(name: '') }
    data_release_strategy       'open'
    study_name_abbreviation     'WTCCC'
    data_access_group           'something'
  end

  factory :study do
    name { |_a| generate :study_name }
    user
    blocked              false
    state                'active'
    enforce_data_release false
    enforce_accessioning false
    reference_genome     { ReferenceGenome.find_by(name: '') }

    # study_metadata

    after(:build) { |study| study.study_metadata = create(:study_metadata, study: study) }
  end

  factory  :budget_division do
    name { |_a| generate :budget_division_name }
  end

  factory :project_metadata, class: Project::Metadata do
    project_cost_code 'Some Cost Code'
    project_funding_model 'Internal'
    budget_division { |budget| budget.association(:budget_division) }
  end

  factory :project do
    name                { |_p| generate :project_name }
    enforce_quotas      false
    approved            true
    state               'active'

    after(:build) { |project| project.project_metadata = create(:project_metadata, project: project) }
  end

  factory :program do
    sequence(:name) { |n| "Program#{n}" }
  end

  factory :project_with_order, parent: :project  do
    after(:build) { |project| project.orders ||= [create(:order, project: project)] }
  end

  factory :study_sample do
    study
    sample
  end

  factory :submission_workflow, class: Submission::Workflow do
    name { |_a| generate :item_name }
    item_label 'library'
  end

  factory :submission do
    user  { |user| user.association(:user) }
  end

  factory :submission_template do
    submission_class_name LinearSubmission.name
    name                  'my_template'
    submission_parameters(workflow_id: 1, request_type_ids_list: [])
    product_catalogue { |pc| pc.association(:single_product_catalogue) }
  end

  factory :request_metadata, class: Request::Metadata do
    read_length 76
    customer_accepts_responsibility false
  end

  #  Automatically generated request types
  factory(:request_metadata_for_request_type_, parent: :request_metadata)

  # Pre-HiSeq sequencing
  factory :request_metadata_for_standard_sequencing, parent: :request_metadata do
    fragment_size_required_from   1
    fragment_size_required_to     21
    read_length                   76

    factory :request_metadata_for_single_ended_sequencing
    factory :request_metadata_for_paired_end_sequencing
  end

  factory :request_metadata_for_standard_sequencing_with_read_length, parent: :request_metadata, class: SequencingRequest::Metadata do
    fragment_size_required_from   1
    fragment_size_required_to     21
    read_length                   76
    association(:owner, factory: :sequencing_request)
  end

  # HiSeq sequencing
  factory :request_metadata_for_hiseq_sequencing, parent: :request_metadata do
    fragment_size_required_from   1
    fragment_size_required_to     21
    read_length                   100

    factory :request_metadata_for_hiseq_paired_end_sequencing
    factory :request_metadata_for_single_ended_hi_seq_sequencing
  end

  factory :hiseq_x_request_metadata, parent: :request_metadata do
    fragment_size_required_from   1
    fragment_size_required_to     21
    read_length                   100

    factory :request_metadata_for_illumina_a_hiseq_x_paired_end_sequencing
    factory :request_metadata_for_illumina_b_hiseq_x_paired_end_sequencing
    factory :request_metadata_for_hiseq_x_paired_end_sequencing
  end

  ('a'..'c').each do |p|
    factory(:"request_metadata_for_illumina_#{p}_single_ended_sequencing", parent: :request_metadata_for_standard_sequencing) {}
    factory(:"request_metadata_for_illumina_#{p}_paired_end_sequencing", parent: :request_metadata_for_standard_sequencing) {}
    # HiSeq sequencing
    factory :"request_metadata_for_illumina_#{p}_hiseq_sequencing", parent: :request_metadata do
      fragment_size_required_from   1
      fragment_size_required_to     21
      read_length                   100
    end
    factory(:"request_metadata_for_illumina_#{p}_hiseq_paired_end_sequencing", parent: :request_metadata_for_hiseq_sequencing) {}
    factory(:"request_metadata_for_illumina_#{p}_single_ended_hi_seq_sequencing", parent: :request_metadata_for_hiseq_sequencing) {}
  end

  # Library manufacture
  factory :request_metadata_for_library_manufacture, parent: :request_metadata do
    fragment_size_required_from   1
    fragment_size_required_to     20
    library_type                  'Standard'

    # TODO: [JG] These are all redundnant,and are a symptom of both our tests dependency
    # on sangerisms within the code,
    factory :request_metadata_for_library_creation
    factory :request_metadata_for_illumina_c_library_creation
    factory :request_metadata_for_multiplexed_library_creation
    factory :request_metadata_for_mx_library_preparation_new
    factory :request_metadata_for_illumina_b_multiplexed_library_creation
    factory :request_metadata_for_illumina_c_multiplexed_library_creation
    factory :request_metadata_for_pulldown_library_creation
    factory :request_metadata_for_pulldown_multiplex_library_preparation
  end

  # Bait libraries
  factory(:request_metadata_for_bait_pulldown, parent: :request_metadata) do
    bait_library_id { |_bl| create(:bait_library).id }
  end
  # set default  metadata factories to every request types which have been defined yet
  RequestType.all.each do |rt|
    factory_name =  :"request_metadata_for_#{rt.name.downcase.gsub(/[^a-z]+/, '_')}"
    next if FactoryGirl.factories.registered?(factory_name)
    factory(factory_name, parent: :request_metadata)
  end

  factory :request_without_submission, class: Request do
    request_type    { |rt| rt.association(:request_type) }
    request_purpose { |rt| rt.association(:request_purpose) }

    #  Ensure that the request metadata is correctly setup based on the request type
    after(:build) do |request|
      next if request.request_type.nil?
      request.request_metadata = build(:"request_metadata_for_#{request.request_type.name.downcase.gsub(/[^a-z]+/, '_')}") if request.request_metadata.new_record?
      request.sti_type = request.request_type.request_class_name
    end
  end

  factory :extended_validator do
    behaviour 'SpeciesValidator'
    options(taxon_id: 9606)
  end

  factory :library_type do
    name 'Standard'
  end

  factory :sample do
    name { |_a| generate :sample_name }

    factory :sample_with_well do
      sequence(:sanger_sample_id) { |n| n.to_s }
      wells { [FactoryGirl.create(:well_with_sample_and_plate)] }
      assets { [wells.first.plate] }
    end

    factory :sample_with_gender do
      association :sample_metadata, factory: :sample_metadata_with_gender
    end
  end

  factory :sample_metadata, class: Sample::Metadata do
    factory :sample_metadata_with_gender do
      gender :male
    end

    factory :sample_metadata_for_api do
      organism 'organism'
      cohort 'cohort'
      country_of_origin 'country_of_origin'
      geographical_region 'geographical_region'
      ethnicity 'ethnicity'
      volume 'volume'
      mother 'mother'
      father 'father'
      replicate 'replicate'
      sample_public_name 'sample_public_name'
      sample_common_name 'sample_common_name'
      sample_description 'sample_description'
      sample_strain_att 'sample_strain_att'
      sample_ebi_accession_number 'sample_ebi_accession_number'
      sample_reference_genome_old 'sample_reference_genome_old'
      sibling 'sibling'
      date_of_sample_collection 'date_of_sample_collection'
      date_of_sample_extraction 'date_of_sample_extraction'
      sample_extraction_method 'sample_extraction_method'
      sample_purified 'sample_purified'
      purification_method 'purification_method'
      concentration 'concentration'
      concentration_determined_by 'concentration_determined_by'
      sample_type 'sample_type'
      sample_storage_conditions 'sample_storage_conditions'
      supplier_name 'supplier_name'
      genotype 'genotype'
      phenotype 'phenotype'
      developmental_stage 'developmental_stage'
      cell_type 'cell_type'
      disease_state 'disease_state'
      compound 'compound'
      immunoprecipitate 'immunoprecipitate'
      growth_condition 'growth_condition'
      rnai 'rnai'
      organism_part 'organism_part'
      time_point 'time_point'
      disease 'disease'
      subject 'subject'
      treatment 'treatment'
    end
  end

  factory :search do
    sequence(:name) { |n| "Search #{n}" }
  end

  sequence :login do |i|
    "user_abc#{i}"
  end

  sequence :tag_group_name do |i|
    "tag_group_#{i}"
  end

  factory :user do
    first_name        'fn'
    last_name         'ln'
    login
    email             { |a| "#{a.login}@example.com".downcase }
    workflow          { |workflow| workflow.association(:submission_workflow) }
    api_key           '123456789'
    password              'password'
    password_confirmation 'password'

    factory :admin do
      roles { |role| [role.association(:admin_role)] }
    end

    factory :manager do
      roles { |role| [role.association(:manager_role)] }
    end

    factory :owner do
      roles { |role| [role.association(:owner_role)] }
    end

    factory :data_access_coordinator do
      roles { |role| [role.association(:data_access_coordinator_role)] }
    end
  end

  factory :role do
    sequence(:name) { |i| "Role #{i}" }
    authorizable nil

    factory :admin_role do
      name 'administrator'
    end

    factory :public_role do
      name 'public'
    end

    factory :manager_role do
      name 'manager'
    end

    factory :data_access_coordinator_role do
      name 'data_access_coordinator'
    end

    factory :owner_role do
      name 'owner'
      authorizable { |i| i.association(:project) }
    end
  end

  factory :custom_text do
    identifier       nil
    differential     nil
    content_type     nil
    content          nil
  end

  factory :asset_group do
    name { |_a| generate :asset_group_name }
    study

    transient do
      asset_type :untagged_well
      asset_count 0
    end

    assets do
      Array.new(asset_count) { create asset_type }
    end
  end

  factory :asset_group_asset do
    association(:asset, factory: :aliquot_receptacle)
    asset_group
  end

  factory :fragment do
  end

  factory :multiplexed_library_tube do
    name    { |_a| generate :asset_name }
    purpose { Tube::Purpose.standard_mx_tube }
  end

  factory :pulldown_multiplexed_library_tube do
    name { |_a| generate :asset_name }
    public_name 'ABC'
  end

  factory :stock_multiplexed_library_tube do
    name    { |_a| generate :asset_name }
    purpose { Tube::Purpose.stock_mx_tube }

    factory :new_stock_multiplexed_library_tube do |_t|
      purpose { |a| a.association(:new_stock_tube_purpose) }
    end
  end

  factory(:new_stock_tube_purpose, class: IlluminaHtp::StockTubePurpose) do |_p|
    name { generate :purpose_name }
    target_type 'StockMultiplexedLibraryTube'
  end

  factory(:request_purpose) do
    key { generate :purpose_name }
  end

  factory(:empty_library_tube, class: LibraryTube) do
    qc_state ''
    name     { |_| generate :asset_name }
    purpose  { Tube::Purpose.standard_library_tube }
  end

  factory(:library_tube, parent: :empty_library_tube) do
    transient do
      sample { create :sample }
      library_type 'Standard'
    end

    after(:create) do |library_tube, evaluator|
      library_tube.aliquots << build(:untagged_aliquot, sample: evaluator.sample, library_type: evaluator.library_type, receptacle: library_tube)
    end
  end

  factory(:tagged_library_tube, class: LibraryTube) do
    transient do
      tag_map_id 1
    end

    after(:create) do |library_tube, evaluator|
      library_tube.aliquots << build(:tagged_aliquot, tag: create(:tag, map_id: evaluator.tag_map_id), receptacle: library_tube)
    end
  end

  factory :pac_bio_library_tube do
    after(:build) do |t|
      t.aliquots.build(sample: (create :sample))
    end
  end

  factory :transfer_request do
    association(:asset, factory: :well)
    association(:target_asset, factory: :well)
    association(:request_type, factory: :transfer_request_type)
    request_purpose
  end

  # A library tube is created from a sample tube through a library creation request!
  factory(:full_library_tube, parent: :library_tube) do
    after(:create) { |tube| create(:library_creation_request, target_asset: tube) }
  end

  factory(:library_creation_request_for_testing_sequencing_requests, class: Request::LibraryCreation) do
    request_type { |_target| RequestType.find_by!(name: 'Library creation') }
    request_purpose { |rp| rp.association(:request_purpose) }
    asset        { |target| target.association(:well_with_sample_and_plate) }
    target_asset { |target| target.association(:empty_well) }
    after(:build) do |request|
      request.request_metadata.fragment_size_required_from = 300
      request.request_metadata.fragment_size_required_to   = 500
    end
  end

  factory :pac_bio_sample_prep_request do |_r|
    target_asset    { |ta| ta.association(:pac_bio_library_tube) }
    asset           { |a|   a.association(:well) }
    submission      { |s|   s.association(:submission) }
    request_purpose { |rp| rp.association(:request_purpose) }
  end

  # A Multiplexed library tube comes from several library tubes, which are themselves created through a
  # number of multiplexed library creation requests.  But the binding to these tubes comes from the parent-child
  # relationships.
  factory :full_multiplexed_library_tube, parent: :multiplexed_library_tube do
    after(:create) do |tube|
      tube.parents << (1..5).map { |_| create(:multiplexed_library_creation_request).target_asset }
    end
  end

  factory :broken_multiplexed_library_tube, parent: :multiplexed_library_tube

  factory :stock_library_tube do
    name     { |_a| generate :asset_name }
    purpose  { Tube::Purpose.stock_library_tube }
  end

  factory :stock_sample_tube do
    name     { |_a| generate :asset_name }
    purpose  { Tube::Purpose.stock_sample_tube }
  end

  factory(:empty_lane, class: Lane) do
    name                { |_l| generate :asset_name }
    external_release    nil
  end

  factory(:lane, parent: :empty_lane) do
  end

  factory  :spiked_buffer do
    name { |_a| generate :asset_name }
    volume 50
  end

  factory  :reference_genome do
    name ' '
  end

  factory :supplier do
    name 'Test supplier'
  end

  factory :sample_manifest do
    study
    supplier
    asset_type 'plate'
    count 1

    factory :sample_manifest_with_samples do
      samples { FactoryGirl.create_list(:sample_with_well, 5) }
    end

    factory :tube_sample_manifest do
      asset_type '1dtube'

      factory :tube_sample_manifest_with_samples do
        samples { FactoryGirl.create_list(:sample_tube, 5).map(&:samples).flatten }
      end
    end
  end

  factory :db_file do
    data 'blahblahblah'
  end

  factory :study_report do
    study

    factory  :pending_study_report

    factory  :completed_study_report do
      report_filename 'progress_report.csv'
      after(:build) { |study_report_file|
        create :db_file, owner: study_report_file, data: Tempfile.open('progress_report.csv').read
      }
    end
  end

  # SLF user stuff
  factory(:slf_manager_role, parent: :role) do
    name 'slf_manager'
  end

  factory(:slf_manager, parent: :user) do
    roles { |role| [role.association(:slf_manager_role)] }
  end

  factory :pre_capture_pool

  factory(:asset_audit) do
    message 'Some message'
    key 'some_key'
    created_by 'abc123'
    witnessed_by 'jane'
    asset
  end

  factory(:faculty_sponsor) do
    name { |_a| generate :faculty_sponsor_name }
  end

  factory(:pooling_method, class: 'RequestType::PoolingMethod') do
    pooling_behaviour 'PlateRow'
    pooling_options(pool_count: 8)
  end

  factory :tag2_layout_template do |_itlt|
    transient do
      oligo { generate :oligo }
    end
    name 'Tag 2 layout template'
    tag { |tag| tag.association :tag, oligo: oligo }
  end

  factory(:messenger_creator) do
    root 'a_plate'
    template 'FluidigmPlateIO'
    purpose { |purpose| purpose.association(:plate_purpose) }
  end

  factory(:barcode_printer) do
    sequence(:name) { |i| "a#{i}bc" }
    association(:barcode_printer_type, factory: :plate_barcode_printer_type)
  end

  factory :uuid do
    association(:resource, factory: :asset)
    external_id { SecureRandom.uuid }
  end

  trait :uuidable do
    transient do
      uuid { SecureRandom.uuid }
    end

    # Using an after build as I need access to both the transient and the resource.
    after(:build) do |resource, context|
      resource.uuid_object = build :uuid, external_id: context.uuid, resource: resource
    end

    after(:create) do |resource, _context|
      resource.uuid_object.save!
    end
  end

  factory :barcode_printer_type do
    sequence(:name) { |i| "Printer Type #{i}" }
  end

  factory :plate_barcode_printer_type, class: BarcodePrinterType96Plate do
    sequence(:name) { |i| "96 Well Plate #{i}" }
    printer_type_id 1
    label_template_name 'sqsc_96plate_label_template'
  end
end
