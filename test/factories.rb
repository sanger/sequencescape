#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2007-2011,2011,2012,2013,2014,2015 Genome Research Ltd.
require 'factory_girl'

Factory.sequence :project_name do |n|
  "Project #{n}"
end

Factory.sequence :study_name do |n|
  "Study #{n}"
end

Factory.sequence :item_name do |n|
  "Item #{n}"
end

Factory.sequence :item_version do |n|
  n
end

Factory.sequence :sample_name do |n|
  "Sample#{n}"
end

Factory.sequence :keys do |n|
  "Key #{n}"
end

Factory.sequence :barcode do |n|
  "DN#{n}"
end

Factory.sequence :request_type_id do |n|
  n
end

Factory.sequence :library_type_id do |n|
  n
end

Factory.sequence :purpose_name do |n|
  "Purpose #{n}"
end

Factory.sequence :billing_reference do |ref|
  ref.to_s
end

Factory.sequence :asset_group_name do |n|
  "Asset_Group #{n}"
end

Factory.sequence :pipeline_name do |n|
  "Lab Pipeline #{n}"
end

Factory.sequence :lab_workflow_name do |n|
  "Lab Workflow #{n}"
end

Factory.sequence :barcode_number do |n|
  "#{n}"
end

Factory.sequence :asset_name do |n|
  "Asset #{n}"
end

Factory.sequence :budget_division_name do |n|
  "Budget Division#{n}"
end

Factory.sequence :faculty_sponsor_name do |n|
  "Faculty Sponsor #{n}"
end

Factory.define :comment do |c|
  c.description
end

Factory.define :aliquot do |a|
  a.sample  {|s| s.association(:sample) }
  a.study   {|s| s.association(:study) }
  a.project {|p| p.association(:project) }
  a.tag     {|t| t.association(:tag) }
  a.tag2    {|t| t.association(:tag) }
end

Factory.define :event do |e|
  e.family          ""
  e.content         ""
  e.message         ""
  e.eventful_type   ""
  e.eventful_id     ""
  e.type            "Event"
end

Factory.define :item do |i|
  i.name              {|a| Factory.next :item_name }
  i.workflow          {|workflow| workflow.association(:submission_workflow)}
  i.count             nil
  i.closed            false
end

Factory.define :study_metadata, :class => Study::Metadata do |m|
  m.faculty_sponsor             { |faculty_sponsor| faculty_sponsor.association(:faculty_sponsor)}
  m.study_description           'Some study on something'
  m.contaminated_human_dna      'No'
  m.contains_human_dna          'No'
  m.commercially_available      'No'
  m.study_type                  StudyType.find_by_name('Not specified')
  m.data_release_study_type     DataReleaseStudyType.find_by_name('genomic sequencing')
  m.reference_genome            ReferenceGenome.find_by_name("")
  m.data_release_strategy       'open'
  m.study_name_abbreviation     'WTCCC'
end

Factory.define :study do |p|
  p.name                 { |a| Factory.next :study_name }
  p.user                 {|user| user.association(:user)}
  p.blocked              false
  p.state                "pending"
  p.enforce_data_release false
  p.enforce_accessioning false
  p.reference_genome     ReferenceGenome.find_by_name("")

  p.after_build { |study| study.study_metadata = Factory(:study_metadata, :study => study) }
end

Factory.define :budget_division do |bd|
 bd.name { |a| Factory.next :budget_division_name }
end

Factory.define :project_metadata, :class => Project::Metadata do |m|
  m.project_cost_code 'Some Cost Code'
  m.project_funding_model 'Internal'
  m.budget_division {|budget| budget.association(:budget_division)}
end

Factory.define :project do |p|
  p.name                { |p| Factory.next :project_name }
  p.enforce_quotas      false
  p.approved            true
  p.state               "active"

  p.after_build { |project| project.project_metadata = Factory(:project_metadata, :project => project) }
end

Factory.define :project_with_order , :parent => :project do |p|
  p.after_build { |project| project.orders ||= [Factory :order, :project => project] }
end

Factory.define :study_sample do |ps|
  ps.study       {|study| study.association(:study)}
  ps.sample      {|sample| sample.association(:sample)}
end

Factory.define :submission_workflow, :class => Submission::Workflow do |p|
  p.name         {|a| Factory.next :item_name }
  p.item_label  "library"
end

Factory.define :submission_template do |submission_template|
  submission_template.submission_class_name LinearSubmission.name
  submission_template.name                  "my_template"
  submission_template.submission_parameters({ :workflow_id => 1, :request_type_ids_list => [] })
end
Factory.define :order_template, :class => SubmissionTemplate do |submission_template|
  submission_template.submission_class_name LinearSubmission.name
  submission_template.name                  "my_template"
  submission_template.submission_parameters({ :workflow_id => 1, :request_type_ids_list => [] })
end

Factory.define :report do |r|
end

Factory.define :request_metadata, :class => Request::Metadata do |m|
  m.read_length 76
  m.customer_accepts_responsibility false
end

# Automatically generated request types
Factory.define(:request_metadata_for_request_type_, :parent => :request_metadata) {}

# Pre-HiSeq sequencing
Factory.define :request_metadata_for_standard_sequencing, :parent => :request_metadata do |m|
  m.fragment_size_required_from   1
  m.fragment_size_required_to     21
  m.read_length                   76
end

Factory.define :request_metadata_for_standard_sequencing_with_read_length, :parent => :request_metadata, :class=>SequencingRequest::Metadata do |m|
  m.fragment_size_required_from   1
  m.fragment_size_required_to     21
  m.read_length                   76
end

Factory.define(:request_metadata_for_single_ended_sequencing, :parent => :request_metadata_for_standard_sequencing) {}
Factory.define(:request_metadata_for_paired_end_sequencing, :parent => :request_metadata_for_standard_sequencing) {}

# HiSeq sequencing
Factory.define :request_metadata_for_hiseq_sequencing, :parent => :request_metadata do |m|
  m.fragment_size_required_from   1
  m.fragment_size_required_to     21
  m.read_length                   100
end
Factory.define(:request_metadata_for_hiseq_paired_end_sequencing, :parent => :request_metadata_for_hiseq_sequencing) {}
Factory.define(:request_metadata_for_single_ended_hi_seq_sequencing, :parent => :request_metadata_for_hiseq_sequencing) {}


('a'..'c').each do |p|
  Factory.define(:"request_metadata_for_illumina_#{p}_single_ended_sequencing", :parent => :request_metadata_for_standard_sequencing) {}
  Factory.define(:"request_metadata_for_illumina_#{p}_paired_end_sequencing", :parent => :request_metadata_for_standard_sequencing) {}
  # HiSeq sequencing
  Factory.define :"request_metadata_for_illumina_#{p}_hiseq_sequencing", :parent => :request_metadata do |m|
    m.fragment_size_required_from   1
    m.fragment_size_required_to     21
    m.read_length                   100
  end
  Factory.define(:"request_metadata_for_illumina_#{p}_hiseq_paired_end_sequencing", :parent => :request_metadata_for_hiseq_sequencing) {}
  Factory.define(:"request_metadata_for_illumina_#{p}_single_ended_hi_seq_sequencing", :parent => :request_metadata_for_hiseq_sequencing) {}
end

# Library manufacture
Factory.define :request_metadata_for_library_manufacture, :parent => :request_metadata do |m|
  m.fragment_size_required_from   1
  m.fragment_size_required_to     20
  m.library_type                  "Standard"
end
Factory.define(:request_metadata_for_library_creation, :parent => :request_metadata_for_library_manufacture) {}
Factory.define(:request_metadata_for_illumina_c_library_creation, :parent => :request_metadata_for_library_manufacture) {}
Factory.define(:request_metadata_for_multiplexed_library_creation, :parent => :request_metadata_for_library_manufacture) {}
Factory.define(:request_metadata_for_mx_library_preparation_new, :parent => :request_metadata_for_library_manufacture) {}
Factory.define(:request_metadata_for_illumina_b_multiplexed_library_creation, :parent => :request_metadata_for_library_manufacture) {}
Factory.define(:request_metadata_for_illumina_c_multiplexed_library_creation, :parent => :request_metadata_for_library_manufacture) {}
Factory.define(:request_metadata_for_pulldown_library_creation, :parent => :request_metadata_for_library_manufacture) {}
Factory.define(:request_metadata_for_pulldown_multiplex_library_preparation, :parent => :request_metadata_for_library_manufacture) {}

# Bait libraries
Factory.define(:request_metadata_for_bait_pulldown, :parent => :request_metadata) do |m|
  m.bait_library_id  {|bait_library| bait_library.association(:bait_library).id}
end
# set default  metadata factories to every request types which have been defined yet
RequestType.all.each do |rt|
  factory_name =  :"request_metadata_for_#{rt.name.downcase.gsub(/[^a-z]+/, '_')}"
  next if Factory.factories[factory_name]
  Factory.define(factory_name, :parent => :request_metadata) {}
end

Factory.define :request_with_submission, :class => Request do |request|
  request.request_type { |rt| rt.association(:request_type) }

  # Ensure that the request metadata is correctly setup based on the request type
  request.after_build do |request|
    next if request.request_type.nil?
    request.request_metadata = Factory.build(:"request_metadata_for_#{request.request_type.name.downcase.gsub(/[^a-z]+/, '_')}") if request.request_metadata.new_record?
    request.sti_type = request.request_type.request_class_name
  end

  # We use after_create so this is called after the after_build of derived class
  # That leave a chance to children factory to build asset beforehand
  request.after_build do |request|
    request.submission = Factory::submission(
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

Factory.define :sequencing_request, :class => SequencingRequest do |request|
  request.request_type { |rt| rt.association(:request_type) }

  # Ensure that the request metadata is correctly setup based on the request type
  request.after_build do |request|
    next if request.request_type.nil?
    request.request_metadata = Factory.build(:"request_metadata_for_standard_sequencing_with_read_length") if request.request_metadata.new_record?
    request.sti_type = request.request_type.request_class_name
  end
end

Factory.define :request_without_assets, :parent => :request_with_submission do |request|
  request.item              {|item|       item.association(:item)}
  request.project           {|pr|         pr.association(:project)}
  request.request_type      {|rt|         rt.association(:request_type)}
  request.state             'pending'
  request.study             {|study|      study.association(:study)}
  request.user              {|user|       user.association(:user)}
  request.workflow          {|workflow|   workflow.association(:submission_workflow)}
end

Factory.define :request, :parent => :request_without_assets do |request|
  # the sample should be setup correctly and the assets should be valid
  request.asset        { |asset| asset.association(:sample_tube)  }
  request.target_asset { |asset| asset.association(:library_tube) }
end

Factory.define :request_with_sequencing_request_type, :parent => :request_without_assets do |request|
  # the sample should be setup correctly and the assets should be valid
  request.asset            { |asset|    asset.association(:library_tube)  }
  request.request_metadata { |metadata| metadata.association(:request_metadata_for_standard_sequencing)}
  request.request_type     { |rt|       rt.association(:sequencing_request_type)}
end

Factory.define :well_request, :parent => :request_without_assets do |request|
  # the sample should be setup correctly and the assets should be valid
  request.request_type { |rt|    rt.association(:well_request_type)}
  request.asset        { |asset| asset.association(:well)  }
  request.target_asset { |asset| asset.association(:well) }
end

Factory.define :request_suitable_for_starting, :parent => :request_without_assets do |request|
  request.asset        { |asset| asset.association(:sample_tube)        }
  request.target_asset { |asset| asset.association(:empty_library_tube) }
end

Factory.define :request_without_item, :class => "Request" do |r|
  r.study         {|pr| pr.association(:study)}
  r.project         {|pr| pr.association(:project)}
  r.user            {|user|     user.association(:user)}
  r.request_type    {|request_type| request_type.association(:request_type)}
  r.workflow        {|workflow| workflow.association(:submission_workflow)}
  r.state           'pending'
  r.after_build { |request| request.submission = Factory::submission(:study => request.initial_study,
                                                                           :project => request.initial_project,
                                                                           :user => request.user,
                                                                           :request_types => [request.request_type.id.to_s],
                                                                           :workflow => request.workflow

                                                                          )
  }
end

Factory.define :request_without_project, :class => Request do |r|
  r.study         {|pr| pr.association(:study)}
  r.item            {|item| item.association(:item)}
  r.user            {|user|     user.association(:user)}
  r.request_type    {|request_type| request_type.association(:request_type)}
  r.workflow        {|workflow| workflow.association(:submission_workflow)}
  r.state           'pending'
end

%w(failed passed pending cancelled).each do |state|
Factory.define :"#{state}_request", :parent =>  :request do |r|
  r.after_create { |request| request.update_attributes!(:state =>state) }
end
end


Factory.define :request_type do |rt|
  rt_value = Factory.next :request_type_id
  rt.name           "Request type #{rt_value}"
  rt.key            "request_type_#{rt_value}"
  rt.deprecated     false
  rt.asset_type     'SampleTube'
  rt.request_class  Request
  rt.order          1
  rt.workflow    {|workflow| workflow.association(:submission_workflow)}
  rt.initial_state   "pending"
end

Factory.define :extended_validator do |ev|
  ev.behaviour 'SpeciesValidator'
  ev.options({:taxon_id=>9606})
end

Factory.define :validated_request_type, :parent => :request_type do |rt|
  rt.after_create do |request_type|
    request_type.extended_validators << Factory(:extended_validator)
  end
end

Factory.define :library_type do |lt|
  lt_value = Factory.next :library_type_id
  lt.name    "Standard"
end

Factory.define :library_types_request_type do |ltrt|
  ltrt.library_type  {|library_type| library_type.association(:library_type)}
  ltrt.is_default true
end

Factory.define :well_request_type, :parent => :request_type do |rt|
  rt.asset_type     'Well'
end

Factory.define :library_creation_request_type, :class => RequestType do |rt|
  rt_value = Factory.next :request_type_id
  rt.name           "LC Request type #{rt_value}"
  rt.key            "request_type_#{rt_value}"
  rt.asset_type     "SampleTube"
  rt.target_asset_type "LibraryTube"
  rt.request_class  LibraryCreationRequest
  rt.order          1
  rt.workflow    {|workflow| workflow.association(:submission_workflow)}
  rt.after_build {|request_type|
    request_type.library_types_request_types << Factory(:library_types_request_type,:request_type=>request_type)
    request_type.request_type_validators << Factory(:library_request_type_validator, :request_type=>request_type)
  }
end
Factory.define :sequencing_request_type, :class => RequestType do |rt|
  rt_value = Factory.next :request_type_id
  rt.name           "Request type #{rt_value}"
  rt.key            "request_type_#{rt_value}"
  rt.asset_type     "LibraryTube"
  rt.request_class  SequencingRequest
  rt.order          1
  rt.workflow    {|workflow| workflow.association(:submission_workflow)}
  rt.after_build {|request_type|
    request_type.request_type_validators << Factory(:sequencing_request_type_validator, :request_type=>request_type)
  }
end

Factory.define :sequencing_request_type_validator, :class => RequestType::Validator do |rtv|
  rtv.request_option 'read_length'
  rtv.valid_options { RequestType::Validator::ArrayWithDefault.new([37, 54, 76, 108],54) }
end

Factory.define :library_request_type_validator, :class => RequestType::Validator do |rtv|
  rtv.request_option 'library_type'
  rtv.valid_options {|rtva| RequestType::Validator::LibraryTypeValidator.new(rtva.request_type.id) }
end

Factory.define :multiplexed_library_creation_request_type, :class => RequestType do |rt|
  rt_value = Factory.next :request_type_id
  rt.name               "MX Request type #{rt_value}"
  rt.key                "request_type_#{rt_value}"
  rt.request_class      MultiplexedLibraryCreationRequest
  rt.asset_type         "SampleTube"
  rt.order              1
  rt.for_multiplexing   true
  rt.workflow           { |workflow| workflow.association(:submission_workflow)}
    rt.after_build {|request_type|
    request_type.library_types_request_types << Factory(:library_types_request_type,:request_type=>request_type)
    request_type.request_type_validators << Factory(:library_request_type_validator, :request_type=>request_type)
  }
end

Factory.define :plate_based_multiplexed_library_creation_request_type, :class => RequestType do |rt|
  rt_value = Factory.next :request_type_id
  rt.name               "MX Request type #{rt_value}"
  rt.key                "request_type_#{rt_value}"
  rt.request_class      MultiplexedLibraryCreationRequest
  rt.asset_type         "Well"
  rt.order              1
  rt.for_multiplexing   true
  rt.workflow           { |workflow| workflow.association(:submission_workflow)}
    rt.after_build {|request_type|
    request_type.library_types_request_types << Factory(:library_types_request_type,:request_type=>request_type)
    request_type.request_type_validators << Factory(:library_request_type_validator, :request_type=>request_type)
  }
end

Factory.define :sample do |s|
  s.name            {|a| Factory.next :sample_name }
end

Factory.define :sample_submission do |sps|
end

Factory.define :search do |s|
end

Factory.define :section do |s|
end

Factory.define :sequence do |s|
end

Factory.define :setting do |s|
  s.name    ''
  s.value   ''
  s.user    {|user| user.association(:user)}
end

Factory.define :user do |u|
  u.first_name        "fn"
  u.last_name         "ln"
  u.login             "abc123"
  u.email             {|a| "#{a.login}@example.com".downcase }
  u.roles             []
  u.workflow          {|workflow| workflow.association(:submission_workflow)}
  u.api_key           "123456789"
end

Factory.define :admin, :class => "User" do |u|
  u.login                 "abc123"
  u.email                 {|a| "#{a.login}@example.com".downcase }
  u.roles                 {|role| [role.association(:admin_role)]}
  u.password              "password"
  u.password_confirmation "password"
  u.workflow              {|workflow| workflow.association(:submission_workflow)}
end

Factory.define :manager, :class => "User" do |u|
  u.login             "gr9"
  u.email             {|a| "#{a.login}@example.com".downcase }
  u.roles             {|role| [role.association(:manager_role)]}
  u.workflow          {|workflow| workflow.association(:submission_workflow)}
end

Factory.define :owner, :class => "User" do |u|
  u.login             "abc123"
  u.email             {|a| "#{a.login}@example.com".downcase}
  u.roles             {|role| [role.association(:owner_role)]}
  u.workflow          {|workflow| workflow.association(:submission_workflow)}
end

Factory.define :role do |r|
  r.sequence(:name)   { |i| "Role #{ i }" }
  r.authorizable       nil
end

Factory.define :admin_role, :class => "Role" do |r|
  r.name            "administrator"
end

Factory.define :public_role do |r|
  r.name          'public'
end

Factory.define :manager_role, :class => 'Role' do |r|
  r.name            "manager"
end

Factory.define :owner_role, :class => 'Role' do |r|
  r.name            "owner"
  r.authorizable    { |i| i.association(:project) }
end

Factory.define :custom_text do |ct|
  ct.identifier       nil
  ct.differential     nil
  ct.content_type     nil
  ct.content          nil
end

Factory.define :asset_group do |ag|
  ag.name     {|a| Factory.next :asset_group_name}
  ag.study    {|study| study.association(:study)}
  ag.assets   []
end

Factory.define :asset_group_asset do |aga|
  aga.asset         {|asset| asset.association(:asset)}
  aga.asset_group   {|asset_group| asset_group.association(:asset_group)}
end

Factory.define :fragment do |fragment|
end

Factory.define :multiplexed_library_tube do |a|
  a.name    {|a| Factory.next :asset_name }
  a.purpose Tube::Purpose.standard_mx_tube
end

Factory.define :pulldown_multiplexed_library_tube do |a|
  a.name                {|a| Factory.next :asset_name }
  a.public_name   "ABC"
end

Factory.define :stock_multiplexed_library_tube do |a|
  a.name    {|a| Factory.next :asset_name }
  a.purpose Tube::Purpose.stock_mx_tube
end

Factory.define :new_stock_multiplexed_library_tube, :class=>StockMultiplexedLibraryTube do |t|
  t.name    {|a| Factory.next :asset_name }
  t.purpose { |a| a.association(:new_stock_tube_purpose) }
end

Factory.define(:new_stock_tube_purpose, :class=>IlluminaHtp::StockTubePurpose) do |p|
  p.name { Factory.next :purpose_name }
end

Factory.define(:empty_library_tube, :class => LibraryTube) do |library_tube|
  library_tube.qc_state ''
  library_tube.name     {|_| Factory.next :asset_name }
  library_tube.purpose  Tube::Purpose.standard_library_tube
end
Factory.define :library_tube, :parent => :empty_library_tube do |library_tube|
  library_tube.after_create do |library_tube|
    library_tube.aliquots.create!(:sample => Factory(:sample))
  end
end
Factory.define :pac_bio_library_tube do
end

# A library tube is created from a sample tube through a library creation request!
Factory.define :full_library_tube, :parent => :library_tube do |library_tube|
  library_tube.after_create { |tube| Factory(:library_creation_request, :target_asset => tube) }
end

Factory.define(:library_creation_request_for_testing_sequencing_requests, :class => Request::LibraryCreation) do |request|
  request.request_type { |target| RequestType.find_by_name('Library creation') or raise StandardError, "Could not find 'Library creation' request type" }
  request.asset        { |target| target.association(:well_with_sample_and_plate) }
  request.target_asset { |target| target.association(:empty_well) }
  request.after_build do |request|
    request.request_metadata.fragment_size_required_from = 300
    request.request_metadata.fragment_size_required_to   = 500
  end
end

Factory.define :library_creation_request, :parent => :request do |request|
  request_type = RequestType.find_by_name('Library creation') or raise "Cannot find 'Library creation' request type"

  request.sti_type      request_type.request_class_name
  request.asset         { |asset| asset.association(:sample_tube) }
  request.request_type  { |type|  type = request_type }
  request.after_create do |request|
    request.request_metadata.update_attributes!(
      :fragment_size_required_from => 100,
      :fragment_size_required_to   => 200,
      :library_type                => 'Standard'
    )
  end
end

# A Multiplexed library tube comes from several library tubes, which are themselves created through a
# number of multiplexed library creation requests.  But the binding to these tubes comes from the parent-child
# relationships.
Factory.define :full_multiplexed_library_tube, :parent => :multiplexed_library_tube do |multiplexed_library_tube|
  multiplexed_library_tube.after_create do |tube|
    tube.parents << (1..5).map { |_| Factory(:multiplexed_library_creation_request).target_asset }
  end
end

Factory.define :broken_multiplexed_library_tube, :parent => :multiplexed_library_tube do |multiplexed_library_tube|

end

Factory.define :multiplexed_library_creation_request, :parent => :request do |request|
  request_type = RequestType.find_by_name('Multiplexed library creation') or raise "Cannot find 'Multiplexed library creation' request type"

  request.sti_type      request_type.request_class_name
  request.asset         { |asset| asset.association(:sample_tube)  }
  request.target_asset  { |asset| asset.association(:library_tube) }
  request.request_type  { |type|  type = request_type }
  request.after_create do |request|
    request.request_metadata.update_attributes!(
      :fragment_size_required_from => 150,
      :fragment_size_required_to   => 400,
      :library_type                => 'Standard'
    )
  end
end

Factory.define :stock_library_tube do |a|
  a.name     {|a| Factory.next :asset_name }
  a.purpose  Tube::Purpose.stock_library_tube
end

Factory.define :stock_sample_tube do |a|
  a.name     {|a| Factory.next :asset_name }
  a.purpose  Tube::Purpose.stock_sample_tube
end

Factory.define(:empty_lane, :class => Lane) do |lane|
  lane.name                {|l| Factory.next :asset_name }
  lane.external_release    nil
end

Factory.define(:lane, :parent => :empty_lane) do |l|
end

Factory.define :spiked_buffer do |a|
  a.name { |a| Factory.next :asset_name }
  a.volume 50
end

Factory.define :reference_genome do |r|
  r.name " "
end

Factory.define :supplier do |a|
  a.name  "Test supplier"
end

Factory.define :sample_manifest do |a|
  a.study     {|wa| wa.association(:study)}
  a.supplier  {|wa| wa.association(:supplier)}
  a.asset_type "plate"
  a.count     1
end

Factory.define :db_file do |f|
  f.data "blahblahblah"
end

Factory.define :pending_study_report, :class => 'StudyReport' do |a|
  a.study    {|wa| wa.association(:study)}
end

Factory.define :completed_study_report, :class => 'StudyReport' do |study_report|
  study_report.study      {|wa| wa.association(:study)}
  study_report.report_filename   "progress_report.csv"
  study_report.after_build { |study_report_file|
    Factory :db_file, :owner => study_report_file, :data => Tempfile.open("progress_report.csv").read
  }
end

# SLF user stuff
Factory.define(:slf_manager_role, :parent => :role) do |role|
  role.name 'slf_manager'
end
Factory.define(:slf_manager, :parent => :user) do |user|
  user.roles { |role| [ role.association(:slf_manager_role) ] }
end

Factory.define(:pre_capture_pool) do
end

Factory.define(:asset_audit) do |audit|
  audit.message "Some message"
  audit.key "some_key"
  audit.created_by  {|user| user.association(:user).login}
  audit.witnessed_by "jane"
  audit.asset  {|asset| asset.association(:asset)}
end

Factory.define(:faculty_sponsor) do |sponsor|
  sponsor.name     { |a| Factory.next :faculty_sponsor_name }
end

Factory.define(:pooling_method, :class=> 'RequestType::PoolingMethod') do |pooling|
  pooling.pooling_behaviour 'PlateRow'
  pooling.pooling_options({:pool_count => 8 })
end

Factory.define(:messenger_creator) do |reporter|
  reporter.root 'a_plate'
  reporter.template 'FluidigmPlateIO'
  reporter.purpose {|purpose| purpose.association(:plate_purpose)}
end

Factory.define :tag2_layout_template do |itlt|
  itlt.name 'Tag 2 layout template'
  itlt.tag {|tag| tag.association :tag }
end

