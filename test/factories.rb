#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2007-2011,2011,2012,2013,2014,2015 Genome Research Ltd.
require 'factory_girl'

FactoryGirl.define do

  factory  :comment  do
    description 'It is okay I guess'
  end

  factory :aliquot do
    sample
    study
    project
    tag
    tag2    {|t| t.association(:tag) }
  end

  factory  :event  do
    family          ""
    content         ""
    message         ""
    eventful_type   ""
    eventful_id     ""
    type            "Event"
  end

  factory  :item  do
    name              {|a| FactoryGirl.generate :item_name }
    version           {|a| FactoryGirl.generate :item_version }
    workflow          {|workflow| workflow.association(:submission_workflow)}
    count             nil
    closed            false
  end

  factory  :study_metadata, :class => Study::Metadata  do
    faculty_sponsor             { |faculty_sponsor| faculty_sponsor.association(:faculty_sponsor)}
    study_description           'Some study on something'
    program                     { Program.find_by_name("General") }
    contaminated_human_dna      'No'
    contains_human_dna          'No'
    commercially_available      'No'
    study_type                  { StudyType.find_by_name('Not specified') }
    data_release_study_type     { DataReleaseStudyType.find_by_name('genomic sequencing') }
    reference_genome            { ReferenceGenome.find_by_name("") }
    data_release_strategy       'open'
    study_name_abbreviation     'WTCCC'
  end

  factory  :study  do
    name                 { |a| FactoryGirl.generate :study_name }
    user                 {|user| user.association(:user)}
    blocked              false
    state                "pending"
    enforce_data_release false
    enforce_accessioning false
    reference_genome     { ReferenceGenome.find_by_name("") }

    study_metadata

    # after(:build) { |study| study.study_metadata = create(:study_metadata, :study => study) }
  end

  factory  :budget_division  do
    name { |a| FactoryGirl.generate :budget_division_name }
  end

  factory  :project_metadata, :class => Project::Metadata  do
    project_cost_code 'Some Cost Code'
    project_funding_model 'Internal'
    budget_division {|budget| budget.association(:budget_division)}
  end

  factory  :project  do
    name                { |p| FactoryGirl.generate :project_name }
    enforce_quotas      false
    approved            true
    state               "active"

    after(:build) { |project| project.project_metadata = create(:project_metadata, :project => project) }
  end

  factory :program do
    name { generate :program_name }
  end

  factory  :project_with_order , :parent => :project  do
    after(:build) { |project| project.orders ||= [create(:order, :project => project)] }
  end

  factory  :study_sample  do
    study       {|study| study.association(:study)}
    sample      {|sample| sample.association(:sample)}
  end

  factory  :submission_workflow, :class => Submission::Workflow  do
    name         {|a| FactoryGirl.generate :item_name }
    item_label  "library"
  end

  factory :submission do
    user  {|user| user.association(:user) }
  end

  factory  :submission_template  do
    submission_class_name LinearSubmission.name
    name                  "my_template"
    submission_parameters({ :workflow_id => 1, :request_type_ids_list => [] })
    product_catalogue {|pc| pc.association(:single_product_catalogue) }
  end

  factory  :report  do
  end

  factory  :request_metadata, :class => Request::Metadata  do
    read_length 76
    customer_accepts_responsibility false
  end

  # Automatically generated request types
  factory(:request_metadata_for_request_type_, :parent => :request_metadata)

  # Pre-HiSeq sequencing
  factory  :request_metadata_for_standard_sequencing, :parent => :request_metadata  do
    fragment_size_required_from   1
    fragment_size_required_to     21
    read_length                   76
  end

  factory  :request_metadata_for_standard_sequencing_with_read_length, :parent => :request_metadata, :class=>SequencingRequest::Metadata  do
    fragment_size_required_from   1
    fragment_size_required_to     21
    read_length                   76
  end

  factory(:request_metadata_for_single_ended_sequencing, :parent => :request_metadata_for_standard_sequencing) {}
  factory(:request_metadata_for_paired_end_sequencing, :parent => :request_metadata_for_standard_sequencing) {}

  # HiSeq sequencing
  factory  :request_metadata_for_hiseq_sequencing, :parent => :request_metadata  do
    fragment_size_required_from   1
    fragment_size_required_to     21
    read_length                   100
  end

  factory  :hiseq_x_request_metadata, :parent => :request_metadata  do
    fragment_size_required_from   1
    fragment_size_required_to     21
    read_length                   100
  end

  factory(:request_metadata_for_hiseq_paired_end_sequencing, :parent => :request_metadata_for_hiseq_sequencing) {}
  factory(:request_metadata_for_single_ended_hi_seq_sequencing, :parent => :request_metadata_for_hiseq_sequencing) {}

  factory(:request_metadata_for_illumina_a_hiseq_x_paired_end_sequencing, :parent => :hiseq_x_request_metadata) {}
  factory(:request_metadata_for_illumina_b_hiseq_x_paired_end_sequencing, :parent => :hiseq_x_request_metadata) {}
  factory(:request_metadata_for_hiseq_x_paired_end_sequencing, :parent => :hiseq_x_request_metadata) {}



  ('a'..'c').each do |p|
    factory(:"request_metadata_for_illumina_#{p}_single_ended_sequencing", :parent => :request_metadata_for_standard_sequencing) {}
    factory(:"request_metadata_for_illumina_#{p}_paired_end_sequencing", :parent => :request_metadata_for_standard_sequencing) {}
    # HiSeq sequencing
    factory  :"request_metadata_for_illumina_#{p}_hiseq_sequencing", :parent => :request_metadata  do
      fragment_size_required_from   1
      fragment_size_required_to     21
      read_length                   100
    end
    factory(:"request_metadata_for_illumina_#{p}_hiseq_paired_end_sequencing", :parent => :request_metadata_for_hiseq_sequencing) {}
    factory(:"request_metadata_for_illumina_#{p}_single_ended_hi_seq_sequencing", :parent => :request_metadata_for_hiseq_sequencing) {}
  end

  # Library manufacture
  factory  :request_metadata_for_library_manufacture, :parent => :request_metadata  do
    fragment_size_required_from   1
    fragment_size_required_to     20
    library_type                  "Standard"
  end
  factory(:request_metadata_for_library_creation, :parent => :request_metadata_for_library_manufacture) {}
  factory(:request_metadata_for_illumina_c_library_creation, :parent => :request_metadata_for_library_manufacture) {}
  factory(:request_metadata_for_multiplexed_library_creation, :parent => :request_metadata_for_library_manufacture) {}
  factory(:request_metadata_for_mx_library_preparation_new, :parent => :request_metadata_for_library_manufacture) {}
  factory(:request_metadata_for_illumina_b_multiplexed_library_creation, :parent => :request_metadata_for_library_manufacture) {}
  factory(:request_metadata_for_illumina_c_multiplexed_library_creation, :parent => :request_metadata_for_library_manufacture) {}
  factory(:request_metadata_for_pulldown_library_creation, :parent => :request_metadata_for_library_manufacture) {}
  factory(:request_metadata_for_pulldown_multiplex_library_preparation, :parent => :request_metadata_for_library_manufacture) {}

  # Bait libraries
  factory(:request_metadata_for_bait_pulldown, :parent => :request_metadata)  do
    bait_library_id  {|bait_library| bait_library.association(:bait_library).id}
  end
  # set default  metadata factories to every request types which have been defined yet
  RequestType.all.each do |rt|
    factory_name =  :"request_metadata_for_#{rt.name.downcase.gsub(/[^a-z]+/, '_')}"
    next if FactoryGirl.factories.registered?(factory_name)
    factory(factory_name, :parent => :request_metadata)
  end

  factory :request_without_submission, :class => Request do
    request_type    { |rt| rt.association(:request_type) }
    request_purpose { |rt| rt.association(:request_purpose) }

    # Ensure that the request metadata is correctly setup based on the request type
    after(:build) do |request|
      next if request.request_type.nil?
      request.request_metadata = build(:"request_metadata_for_#{request.request_type.name.downcase.gsub(/[^a-z]+/, '_')}") if request.request_metadata.new_record?
      request.sti_type = request.request_type.request_class_name
    end
  end


  factory  :request_with_submission, :class => Request  do
    request_type { |rt| rt.association(:request_type) }

    # Ensure that the request metadata is correctly setup based on the request type
    after(:build) do |request|
      next if request.request_type.nil?
      request.request_metadata = build(:"request_metadata_for_#{request.request_type.name.downcase.gsub(/[^a-z]+/, '_')}") if request.request_metadata.new_record?
      request.sti_type = request.request_type.request_class_name
    end

    # We use after(:create) so this is called after the after(:build) of derived class
    # That leave a chance to children factory to build asset beforehand
    after(:build) do |request|
      request.submission = FactoryHelp::submission(
        :workflow => request.workflow,
        :study => request.initial_study,
        :project => request.initial_project,
        :request_types => [request.request_type.try(:id)].compact.map(&:to_s),
        :user => request.user,
        :assets => [request.asset].compact,
        :request_options => request.request_metadata.attributes
      ) unless request.submission
    end
  end

  factory  :sequencing_request, :class => SequencingRequest  do
    request_type     { |rt| rt.association(:request_type) }
    request_purpose { |rt| rt.association(:request_purpose) }

    # Ensure that the request metadata is correctly setup based on the request type
    after(:build) do |request|
      next if request.request_type.nil?
      request.request_metadata = build(:"request_metadata_for_standard_sequencing_with_read_length", :request=>request, :owner=>request) if request.request_metadata.new_record?
      # request.request_metadata.owner = request
      request.sti_type = request.request_type.request_class_name
    end

    after(:create) do |request|
      request.request_metadata.owner = request
    end
  end

  factory  :request_without_assets, :parent => :request_with_submission  do
    item              {|item|       item.association(:item)}
    project           {|pr|         pr.association(:project)}
    request_type      {|rt|         rt.association(:request_type)}
    request_purpose   {|rp|         rp.association(:request_purpose)}
    state             'pending'
    study             {|study|      study.association(:study)}
    user              {|user|       user.association(:user)}
    workflow          {|workflow|   workflow.association(:submission_workflow)}
  end

  factory  :request, :parent => :request_without_assets  do
    # the sample should be setup correctly and the assets should be valid
    asset           { |asset| asset.association(:sample_tube)  }
    target_asset    { |asset| asset.association(:library_tube) }
    request_purpose { |rp|    rp.association(:request_purpose) }
  end

  factory  :request_with_sequencing_request_type, :parent => :request_without_assets  do
    # the sample should be setup correctly and the assets should be valid
    asset            { |asset|    asset.association(:library_tube)  }
    request_metadata { |metadata| metadata.association(:request_metadata_for_standard_sequencing)}
    request_type     { |rt|       rt.association(:sequencing_request_type)}
  end

  factory  :well_request, :parent => :request_without_assets  do
    # the sample should be setup correctly and the assets should be valid
    request_type { |rt|    rt.association(:well_request_type)}
    asset        { |asset| asset.association(:well)  }
    target_asset { |asset| asset.association(:well) }
  end

  factory  :request_suitable_for_starting, :parent => :request_without_assets  do
    asset        { |asset| asset.association(:sample_tube)        }
    target_asset { |asset| asset.association(:empty_library_tube) }
  end

  factory  :request_without_item, :class => "Request"  do
    study         {|pr| pr.association(:study)}
    project         {|pr| pr.association(:project)}
    user            {|user|     user.association(:user)}
    request_type    {|request_type| request_type.association(:request_type)}
    request_purpose { |rt| rt.association(:request_purpose) }
    workflow        {|workflow| workflow.association(:submission_workflow)}
    state           'pending'
    after(:build) { |request| request.submission = FactoryHelp::submission(:study => request.initial_study,
                                                                             :project => request.initial_project,
                                                                             :user => request.user,
                                                                             :request_types => [request.request_type.id.to_s],
                                                                             :workflow => request.workflow

                                                                            )
    }
  end

  factory  :request_without_project, :class => Request  do
    study         {|pr| pr.association(:study)}
    item            {|item| item.association(:item)}
    user            {|user|     user.association(:user)}
    request_type    {|request_type| request_type.association(:request_type)}
  request_purpose { |rt| rt.association(:request_purpose) }
    workflow        {|workflow| workflow.association(:submission_workflow)}
    state           'pending'
  end

  %w(failed passed pending cancelled).each do |request_state|
    factory  :"#{request_state}_request", :parent =>  :request  do
      state request_state
    end
  end

  factory :pooled_cherrypick_request do
    asset      {|asset| asset.association(:well_with_sample_and_without_plate)}
    request_purpose { |rt| rt.association(:request_purpose) }
  end

  factory  :request_type  do
    name           { FactoryGirl.generate :request_type_name }
    key            { FactoryGirl.generate :request_type_key }
    deprecated     false
    asset_type     'SampleTube'
    request_class  Request
    order          1
    workflow    {|workflow| workflow.association(:submission_workflow)}
    initial_state   "pending"
    request_purpose { |rt| rt.association(:request_purpose) }
  end

  factory  :extended_validator  do
    behaviour 'SpeciesValidator'
    options({:taxon_id=>9606})
  end

  factory  :validated_request_type, :parent => :request_type  do
    after(:create) do |request_type|
      request_type.extended_validators << create(:extended_validator)
    end
  end

  factory  :library_type  do
    name    "Standard"
  end

  factory  :library_types_request_type  do
    library_type  {|library_type| library_type.association(:library_type)}
    is_default true
  end

  factory  :well_request_type, :parent => :request_type  do
    asset_type     'Well'
    request_class CustomerRequest
  end

  factory  :library_creation_request_type, :class => RequestType  do
    request_purpose { |rt| rt.association(:request_purpose) }
    name           { FactoryGirl.generate :request_type_name }
    key            { FactoryGirl.generate :request_type_key }
    asset_type     "SampleTube"
    target_asset_type "LibraryTube"
    request_class  LibraryCreationRequest
    order          1
    workflow    {|workflow| workflow.association(:submission_workflow)}
    after(:build) {|request_type|
      request_type.library_types_request_types << create(:library_types_request_type,:request_type=>request_type)
      request_type.request_type_validators << create(:library_request_type_validator, :request_type=>request_type)
    }
  end

  factory  :sequencing_request_type, :class => RequestType  do
    name           { FactoryGirl.generate :request_type_name }
    key            { FactoryGirl.generate :request_type_key }
    request_purpose { |rt| rt.association(:request_purpose) }
    asset_type     "LibraryTube"
    request_class  SequencingRequest
    order          1
    workflow    {|workflow| workflow.association(:submission_workflow)}
    after(:build) {|request_type|
      request_type.request_type_validators << create(:sequencing_request_type_validator, :request_type=>request_type)
    }
  end

  factory  :sequencing_request_type_validator, :class => RequestType::Validator  do
    request_option 'read_length'
    valid_options { RequestType::Validator::ArrayWithDefault.new([37, 54, 76, 108],54) }
  end

  factory  :library_request_type_validator, :class => RequestType::Validator  do
    request_option 'library_type'
    valid_options {|rtva| RequestType::Validator::LibraryTypeValidator.new(rtva.request_type.id) }
  end

  factory  :multiplexed_library_creation_request_type, :class => RequestType  do
    name           { FactoryGirl.generate :request_type_name }
    key            { FactoryGirl.generate :request_type_key }
    request_purpose { |rt| rt.association(:request_purpose) }
    request_class      MultiplexedLibraryCreationRequest
    asset_type         "SampleTube"
    order              1
    for_multiplexing   true
    workflow           { |workflow| workflow.association(:submission_workflow)}
      after(:build) {|request_type|
      request_type.library_types_request_types << create(:library_types_request_type,:request_type=>request_type)
      request_type.request_type_validators << create(:library_request_type_validator, :request_type=>request_type)
    }
  end

  factory  :plate_based_multiplexed_library_creation_request_type, :class => RequestType  do
    name           { FactoryGirl.generate :request_type_name }
    key            { FactoryGirl.generate :request_type_key }
    request_purpose { |rt| rt.association(:request_purpose) }
    request_class      MultiplexedLibraryCreationRequest
    asset_type         "Well"
    order              1
    for_multiplexing   true
    workflow           { |workflow| workflow.association(:submission_workflow)}
      after(:build) {|request_type|
      request_type.library_types_request_types << create(:library_types_request_type,:request_type=>request_type)
      request_type.request_type_validators << create(:library_request_type_validator, :request_type=>request_type)
    }
  end

  factory  :sample  do
    name            {|a| FactoryGirl.generate :sample_name }

    factory :sample_with_well do
      sequence(:sanger_sample_id) {|n| n.to_s }
      wells { [ FactoryGirl.create(:well_with_sample_and_plate)]}
      assets { [ wells.first.plate ] }
    end

  end

  factory  :sample_submission  do
  end

  factory  :search  do
  end

  factory  :section  do
  end

  factory  :sequence  do
  end

  factory  :setting  do
    name    ''
    value   ''
    user    {|user| user.association(:user)}
  end

  factory  :user  do
    first_name        "fn"
    last_name         "ln"
    login             "abc123"
    email             {|a| "#{a.login}@example.com".downcase }
    roles             []
    workflow          {|workflow| workflow.association(:submission_workflow)}
    api_key           "123456789"
  end

  factory  :admin, :class => "User"  do
    login                 "abc123"
    email                 {|a| "#{a.login}@example.com".downcase }
    roles                 {|role| [role.association(:admin_role)]}
    password              "password"
    password_confirmation "password"
    workflow              {|workflow| workflow.association(:submission_workflow)}
  end

  factory  :manager, :class => "User"  do
    login             "gr9"
    email             {|a| "#{a.login}@example.com".downcase }
    roles             {|role| [role.association(:manager_role)]}
    workflow          {|workflow| workflow.association(:submission_workflow)}
  end

  factory  :owner, :class => "User"  do
    login             "abc123"
    email             {|a| "#{a.login}@example.com".downcase}
    roles             {|role| [role.association(:owner_role)]}
    workflow          {|workflow| workflow.association(:submission_workflow)}
  end

  factory  :data_access_coordinator, :class => "User"  do
    login                 "abc123"
    email                 {|a| "#{a.login}@example.com".downcase }
    roles                 {|role| [role.association(:data_access_coordinator_role)]}
    workflow              {|workflow| workflow.association(:submission_workflow)}
  end

  factory  :role  do
    sequence(:name)   { |i| "Role #{ i }" }
    authorizable       nil
  end

  factory  :admin_role, :class => "Role"  do
    name            "administrator"
  end

  factory  :public_role  do
    name          'public'
  end

  factory  :manager_role, :class => 'Role'  do
    name            "manager"
  end

  factory  :data_access_coordinator_role, :class => 'Role'  do
    name            "data_access_coordinator"
  end

  factory  :owner_role, :class => 'Role'  do
    name            "owner"
    authorizable    { |i| i.association(:project) }
  end

  factory  :custom_text  do
    identifier       nil
    differential     nil
    content_type     nil
    content          nil
  end

  factory  :asset_group  do
    name     {|a| FactoryGirl.generate :asset_group_name}
    study    {|study| study.association(:study)}
    assets   []
  end

  factory  :asset_group_asset  do
    asset         {|asset| asset.association(:asset)}
    asset_group   {|asset_group| asset_group.association(:asset_group)}
  end

  factory  :fragment  do
  end

  factory  :multiplexed_library_tube  do
    name    {|a| FactoryGirl.generate :asset_name }
    purpose { Tube::Purpose.standard_mx_tube }
  end

  factory  :pulldown_multiplexed_library_tube  do
    name                {|a| FactoryGirl.generate :asset_name }
    public_name   "ABC"
  end

  factory  :stock_multiplexed_library_tube  do
    name    {|a| FactoryGirl.generate :asset_name }
    purpose { Tube::Purpose.stock_mx_tube }
  end

  factory :new_stock_multiplexed_library_tube, :class=>StockMultiplexedLibraryTube do |t|
    name    {|a| FactoryGirl.generate :asset_name }
    purpose { |a| a.association(:new_stock_tube_purpose) }
  end

  factory(:new_stock_tube_purpose, :class=>IlluminaHtp::StockTubePurpose) do |p|
    name { FactoryGirl.generate :purpose_name }
  end

  factory(:request_purpose) do |rp|
    rp.key { FactoryGirl.generate :purpose_name }
  end

  factory(:empty_library_tube, :class => LibraryTube)  do
    qc_state ''
    name     {|_| FactoryGirl.generate :asset_name }
    purpose  { Tube::Purpose.standard_library_tube }
  end
  factory(:library_tube, :parent => :empty_library_tube) do
    after(:create) do |library_tube|
      library_tube.aliquots.create!(:sample => create(:sample))
    end
  end

  factory :pac_bio_library_tube do
    after(:build) do |t|
      t.aliquots.build(:sample=>(create :sample))
    end
  end

  factory :transfer_request do |tr|
    request_purpose {|rp| rp.association(:request_purpose)}
  end

  # A library tube is created from a sample tube through a library creation request!
  factory(:full_library_tube, :parent => :library_tube)  do
    after(:create) { |tube| create(:library_creation_request, :target_asset => tube) }
  end

  factory(:library_creation_request_for_testing_sequencing_requests, :class => Request::LibraryCreation)  do
    request_type { |target| RequestType.find_by_name('Library creation') or raise StandardError, "Could not find 'Library creation' request type" }
    request_purpose { |rp| rp.association(:request_purpose) }
    asset        { |target| target.association(:well_with_sample_and_plate) }
    target_asset { |target| target.association(:empty_well) }
    after(:build) do |request|
      request.request_metadata.fragment_size_required_from = 300
      request.request_metadata.fragment_size_required_to   = 500
    end
  end

  factory(:library_creation_request, :parent => :request) do
    sti_type      { RequestType.find_by_name('Library creation').request_class_name }
    asset         { |asset| asset.association(:sample_tube) }
    request_type  { |type|  RequestType.find_by_name!('Library creation')}
    after(:create) do |request|
      request.request_metadata.update_attributes!(
        :fragment_size_required_from => 100,
        :fragment_size_required_to   => 200,
        :library_type                => 'Standard'
      )
    end
  end

  factory :pac_bio_sample_prep_request do |r|
    target_asset    {|ta| ta.association(:pac_bio_library_tube)}
    asset           {|a|   a.association(:well) }
    submission      {|s|   s.association(:submission)}
    request_purpose {|rp| rp.association(:request_purpose)}
  end

  # A Multiplexed library tube comes from several library tubes, which are themselves created through a
  # number of multiplexed library creation requests.  But the binding to these tubes comes from the parent-child
  # relationships.
  factory  :full_multiplexed_library_tube, :parent => :multiplexed_library_tube  do
    after(:create) do |tube|
      tube.parents << (1..5).map { |_| create(:multiplexed_library_creation_request).target_asset }
    end
  end

  factory  :broken_multiplexed_library_tube, :parent => :multiplexed_library_tube

  factory  :multiplexed_library_creation_request, :parent => :request  do
    sti_type      { RequestType.find_by_name('Multiplexed library creation').request_class_name }
    asset         { |asset| asset.association(:sample_tube)  }
    target_asset  { |asset| asset.association(:library_tube) }
    request_type  { RequestType.find_by_name('Multiplexed library creation') }
    after(:create) do |request|
      request.request_metadata.update_attributes!(
        :fragment_size_required_from => 150,
        :fragment_size_required_to   => 400,
        :library_type                => 'Standard'
      )
    end
  end

  factory  :stock_library_tube  do
    name     {|a| FactoryGirl.generate :asset_name }
    purpose  { Tube::Purpose.stock_library_tube }
  end

  factory  :stock_sample_tube  do
    name     {|a| FactoryGirl.generate :asset_name }
    purpose  { Tube::Purpose.stock_sample_tube }
  end

  factory(:empty_lane, :class => Lane)  do
    name                {|l| FactoryGirl.generate :asset_name }
    external_release    nil
  end

  factory(:lane, :parent => :empty_lane)  do
  end

  factory  :spiked_buffer  do
    name { |a| FactoryGirl.generate :asset_name }
    volume 50
  end

  factory  :reference_genome  do
    name " "
  end

  factory  :supplier  do
    name  "Test supplier"
  end

  factory :sample_manifest do
    study     {|wa| wa.association(:study)}
    supplier  {|wa| wa.association(:supplier)}
    asset_type "plate"
    count     1

    factory :sample_manifest_with_samples do
      samples { FactoryGirl.create_list(:sample_with_well, 5)}
    end
  end

  factory :tube_sample_manifest, class: SampleManifest do
    study     {|wa| wa.association(:study)}
    supplier  {|wa| wa.association(:supplier)}
    asset_type "1dtube"
    count     1

    factory :tube_sample_manifest_with_samples do
      samples { FactoryGirl.create_list(:sample_tube, 5).map(&:sample) }
    end
  end

  factory  :db_file  do
    data "blahblahblah"
  end

  factory  :pending_study_report, :class => 'StudyReport'  do
    study    {|wa| wa.association(:study)}
  end

  factory  :completed_study_report, :class => 'StudyReport' do
    study      {|wa| wa.association(:study)}
    report_filename   "progress_report.csv"
    after(:build) { |study_report_file|
      create :db_file, :owner => study_report_file, :data => Tempfile.open("progress_report.csv").read
    }
  end

  # SLF user stuff
  factory(:slf_manager_role, :parent => :role)  do
    name 'slf_manager'
  end

  factory(:slf_manager, :parent => :user)  do
    roles { |role| [ role.association(:slf_manager_role) ] }
  end

  factory :pre_capture_pool

  factory(:asset_audit)  do
    message "Some message"
    key "some_key"
    created_by  {|user| user.association(:user).login}
    witnessed_by "jane"
    asset  {|asset| asset.association(:asset)}
  end

  factory(:faculty_sponsor) do
    name  {|a| FactoryGirl.generate :faculty_sponsor_name }
  end

  factory(:pooling_method, :class=> 'RequestType::PoolingMethod')  do
    pooling_behaviour 'PlateRow'
    pooling_options({:pool_count => 8 })
  end

  factory :tag2_layout_template do |itlt|
    name 'Tag 2 layout template'
    tag {|tag| tag.association :tag }
  end

  factory(:messenger_creator)  do
    root 'a_plate'
    template 'FluidigmPlateIO'
    purpose {|purpose| purpose.association(:plate_purpose)}
  end

  factory(:barcode_printer) do
    name 'd304bc'
    barcode_printer_type_id 2
  end
end
