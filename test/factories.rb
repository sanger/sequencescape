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

Factory.define :billing_event do |be|
  be.kind "charge"
  be.reference {|reference| Factory.next :billing_reference }
  be.created_by "abc123@example.com"
  be.project {|project| project.association(:project)}
end

Factory.define :comment do |c|
  c.description
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
  m.budget_division {|budget| budget.association(:budget_division)} 
end

Factory.define :project do |p|
  p.name                { |p| Factory.next :project_name }
  p.enforce_quotas      false
  p.approved            true
  p.state               "active"

  p.after_build { |project| project.project_metadata = Factory(:project_metadata, :project => project) }
end

Factory.define :study_sample do |ps|
  ps.study       {|study| study.association(:study)}
  ps.sample      {|sample| sample.association(:sample)}
end

Factory.define :submission_workflow, :class => Submission::Workflow do |p|
  p.name         {|a| Factory.next :item_name }
  p.item_label  "library"
end

Factory.define :submission do |submission|
    submission.workflow              {|workflow| workflow.association(:submission_workflow)}
    submission.study                 {|study| study.association(:study)}
    submission.project               {|project| project.association(:project)}
    submission.user                  {|user| user.association(:user)}
    submission.item_options          {}
    submission.request_options       {}
    submission.assets                []
    submission.request_types         { [ Factory(:request_type).id ] }
end

Factory.define :submission_template do |submission_template|
  submission_template.submission_class_name Submission.name
  submission_template.name                  "my_template"
  submission_template.submission_parameters({ :workflow_id => 1, :request_type_ids_list => [] })
end

Factory.define :project_quota, :class => Quota do |quota|
  quota.project         {|project| project.association(:project)}
  quota.request_type    {|request_type| request_type.association(:request_type)}
  quota.limit           0
end

Factory.define :report do |r|
end

Factory.define :request_metadata, :class => Request::Metadata do |m|
  m.read_length 76
end

Factory.define :request do |r|
  r.asset             {|asset|      asset.association(:asset)}
  r.item              {|item|       item.association(:item)}
  r.project           {|pr|         pr.association(:project)}
  r.request_type      {|rt|         rt.association(:request_type)}
  r.sample            {|sample|     sample.association(:sample)}
  r.state             'pending'     
  r.study             {|study|      study.association(:study)}
  r.submission        {|submission| submission.association(:submission)}
  r.target_asset      {|asset|      asset.association(:asset)}
  r.user              {|user|       user.association(:user)}
  r.workflow          {|workflow|   workflow.association(:submission_workflow)}

  r.after_build { |request| request.request_metadata = Factory(:request_metadata, :request => request) }
end

Factory.define :request_without_item, :class => "Request" do |r|
  r.study         {|pr| pr.association(:study)}
  r.project         {|pr| pr.association(:project)}
  r.user            {|user|     user.association(:user)}
  r.request_type    {|request_type| request_type.association(:request_type)}
  r.workflow        {|workflow| workflow.association(:submission_workflow)}
  r.state           'pending'
  r.submission      {|submission| submission.association(:submission)}
end

Factory.define :request_without_project, :class => "Request" do |r|
  r.study         {|pr| pr.association(:study)}
  r.item            {|item| item.association(:item)}
  r.user            {|user|     user.association(:user)}
  r.request_type    {|request_type| request_type.association(:request_type)}
  r.workflow        {|workflow| workflow.association(:submission_workflow)}
  r.state           'pending'
  r.submission      {|submission| submission.association(:submission)}
end

Factory.define :failed_request, :class => Request do |r|
  r.user            {|user|     user.association(:user)}
  r.request_type    {|request_type| request_type.association(:request_type)}
  r.state           'failed'
end

Factory.define :passed_request, :class => Request do |r|
  r.user            {|user|     user.association(:user)}
  r.request_type    {|request_type| request_type.association(:request_type)}
  r.state           'passed'
end

Factory.define :pending_request, :class => Request do |r|
  r.user            {|user|     user.association(:user)}
  r.request_type    {|request_type| request_type.association(:request_type)}
  r.state           'pending'
end

Factory.define :cancelled_request, :class => Request do |r|
  r.user            {|user|     user.association(:user)}
  r.request_type    {|request_type| request_type.association(:request_type)}
  r.state           'cancelled'
end


Factory.define :request_type do |rt|
  rt_value = Factory.next :request_type_id
  rt.name           "Request type #{rt_value}"
  rt.key            "request_type_#{rt_value}"
  rt.request_class  Request
  rt.order          1
  rt.workflow    {|workflow| workflow.association(:submission_workflow)}
end

Factory.define :library_creation_request_type, :class => RequestType do |rt|
  rt_value = Factory.next :request_type_id
  rt.name           "Request type #{rt_value}"
  rt.key            "request_type_#{rt_value}"
  rt.request_class  LibraryCreationRequest
  rt.order          1
  rt.workflow    {|workflow| workflow.association(:submission_workflow)}
end
Factory.define :sequencing_request_type, :class => RequestType do |rt|
  rt_value = Factory.next :request_type_id
  rt.name           "Request type #{rt_value}"
  rt.key            "request_type_#{rt_value}"
  rt.request_class  SequencingRequest
  rt.order          1
  rt.workflow    {|workflow| workflow.association(:submission_workflow)}
end

Factory.define :multiplexed_library_creation_request_type, :class => RequestType do |rt|
  rt_value = Factory.next :request_type_id
  rt.name               "Request type #{rt_value}"
  rt.key                "request_type_#{rt_value}"
  rt.request_class      MultiplexedLibraryCreationRequest
  rt.order              1
  rt.for_multiplexing   true
  rt.workflow           { |workflow| workflow.association(:submission_workflow)}
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

Factory.define :well_attribute do |w|
  w.concentration       23.2
  w.current_volume      15
end

Factory.define :well do |a|
  a.name                {|a| Factory.next :asset_name }
  a.value               ""
  a.qc_state            ""
  a.resource            nil
  a.barcode             nil
  a.well_attribute      {|wa| wa.association(:well_attribute)}
end

Factory.define :fragment do |fragment|
end

Factory.define :multiplexed_library_tube do |a|
  a.name                {|a| Factory.next :asset_name }
end

Factory.define :pulldown_multiplexed_library_tube do |a|
  a.name                {|a| Factory.next :asset_name }
  a.public_name   "ABC"
end

Factory.define :stock_multiplexed_library_tube do |a|
  a.name                {|a| Factory.next :asset_name }
end

Factory.define :library_tube do |library_tube|
  library_tube.name {|_| Factory.next :asset_name }
end

# A library tube is created from a sample tube through a library creation request!
Factory.define :full_library_tube, :parent => :library_tube do |library_tube|
  library_tube.after_create { |tube| Factory(:library_creation_request, :target_asset => tube) }
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
  a.name                {|a| Factory.next :asset_name }
end

Factory.define :stock_sample_tube do |a|
  a.name                {|a| Factory.next :asset_name }
end

Factory.define :lane do |l|
  l.name                {|l| Factory.next :asset_name }
  l.external_release    nil
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

Factory.define :pending_study_report, :class => 'StudyReport' do |a|
  a.study    {|wa| wa.association(:study)}
end

Factory.define :completed_study_report, :class => 'StudyReport' do |study_report|
  study_report.study    {|wa| wa.association(:study)}
  study_report.after_build { |study_report_file|
    study_report_file.report = Tempfile.open("progress_report.csv")
  }
end

# SLF user stuff
Factory.define(:slf_manager_role, :parent => :role) do |role|
  role.name 'slf_manager'
end
Factory.define(:slf_manager, :parent => :user) do |user|
  user.roles { |role| [ role.association(:slf_manager_role) ] }
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
