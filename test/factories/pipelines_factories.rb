require 'factory_girl'
require 'control_request_type_creation'

Pipeline.send(:include, ControlRequestTypeCreation)

Factory.sequence :pipeline_name do |n|
  "Pipeline #{n}"
end

Factory.sequence :lab_workflow_name do |n|
  "Workflow #{n}"
end

Factory.sequence :barcode_number do |n|
  "#{n}"
end

Factory.sequence :asset_name do |n|
  "Asset #{n}"
end


Factory.define :asset do |a|
  a.name                {|a| Factory.next :asset_name }
  a.value               ""
  a.qc_state            ""
  a.resource            nil
  a.barcode             {|a| Factory.next :barcode_number }
  a.barcode_prefix      {|b| b.association(:barcode_prefix)}
end

Factory.define :plate do |a|
  a.plate_purpose { |_| PlatePurpose.find_by_name('Stock plate') }
  a.name                "Plate name"
  a.value               ""
  a.qc_state            ""
  a.resource            nil
  a.sti_type            "Plate"
  a.barcode             {|a| Factory.next :barcode_number }
end

Factory.define :control_plate do |a|
  a.plate_purpose { |_| PlatePurpose.find_by_name('Stock plate') }
  a.name                "Control Plate name"
  a.value               ""
  a.descriptors         []
  a.descriptor_fields   ""
  a.qc_state            ""
  a.resource            nil
  a.sti_type            "ControlPlate"
  a.barcode             {|a| Factory.next :barcode_number }
end

Factory.define :dilution_plate do |a|
  a.plate_purpose { |_| PlatePurpose.find_by_name('Stock plate') }
  a.barcode             {|a| Factory.next :barcode_number }
end
Factory.define :gel_dilution_plate do |a|
  a.plate_purpose { |_| PlatePurpose.find_by_name('Gel Dilution') }
  a.barcode             {|a| Factory.next :barcode_number }
end
Factory.define :pico_assay_a_plate do |a|
  a.plate_purpose { |_| PlatePurpose.find_by_name('Pico Assay A') }
  a.barcode             {|a| Factory.next :barcode_number }
end
Factory.define :pico_assay_b_plate do |a|
  a.plate_purpose { |_| PlatePurpose.find_by_name('Pico Assay B') }
  a.barcode             {|a| Factory.next :barcode_number }
end
Factory.define :pico_assay_plate do |a|
  a.plate_purpose { |_| PlatePurpose.find_by_name('Stock plate') }
  a.barcode             {|a| Factory.next :barcode_number }
end
Factory.define :pico_dilution_plate do |a|
  a.plate_purpose { |_| PlatePurpose.find_by_name('Pico Dilution') }
  a.barcode             {|a| Factory.next :barcode_number }
end
Factory.define :sequenom_qc_plate do |a|
  a.plate_purpose { |_| PlatePurpose.find_by_name('Sequenom') }
  a.barcode             {|a| Factory.next :barcode_number }
end
Factory.define :working_dilution_plate do |a|
  a.plate_purpose { |_| PlatePurpose.find_by_name('Working Dilution') }
  a.barcode             {|a| Factory.next :barcode_number }
end

Factory.define :batch do |b|
  b.item_limit            4
  b.user                  {|user| user.association(:user)}
  b.pipeline              {|pipeline| pipeline.association(:pipeline)}
  b.state                 "pending"
  b.qc_pipeline_id        ""
  b.qc_state              "qc_pending"
  b.assignee_id           {|user| user.association(:user)}
  b.production_state      nil
end

Factory.define :control do |c|
  c.name                  "New control"
  c.pipeline              {|pipeline| pipeline.association(:pipeline)}
end

Factory.define :descriptor do |d|
  d.name                "Desc name"
  d.value               ""
  d.selection           ""
  d.task                {|task| task.association(:task)}
  d.kind                ""
  d.required            0
  d.sorter              nil
  d.key                 ""
end

Factory.define :pipeline_event do |e|
  e.description           ""
  e.descriptors           ""
  e.descriptor_fields     ""
  e.eventful_id           nil
  e.eventful_type         ""
  e.filename              ""
  e.data                  ""
  e.message               ""
  e.user_id               nil
end

Factory.define :family do |f|
  f.name                  "New Family name"
  f.description           "Something goes here"
  f.relates_to            ""
  f.task                  { |task|     task.association(:task) }
  f.workflow              { |workflow| workflow.association(:lab_workflow) }
end


Factory.define :lab_workflow_for_pipeline, :class => LabInterface::Workflow do |w|
  w.name                  {|a| Factory.next :lab_workflow_name }
  w.item_limit            2
  w.locale                "Internal"
end

Factory.define :pipeline, :class => Pipeline do |p|
  p.name                  {|a| Factory.next :pipeline_name }
  p.automated             false
  p.active                true
  p.next_pipeline_id      nil
  p.previous_pipeline_id  nil
  p.location              {|location| location.association(:location)}
  p.after_build          do |pipeline|
    pipeline.request_types << Factory(:request_type )
    pipeline.add_control_request_type
    pipeline.build_workflow(:name => pipeline.name, :item_limit => 2, :locale => 'Internal') if pipeline.workflow.nil?
  end
end

Factory.define :qc_pipeline do |p|
  p.name                  {|a| Factory.next :pipeline_name }
  p.automated             false
  p.active                true
  p.next_pipeline_id      nil
  p.previous_pipeline_id  nil
  p.location              {|location| location.association(:location)}

  p.after_build do |pipeline|
    pipeline.request_types << Factory(:request_type )
    pipeline.add_control_request_type
    pipeline.build_workflow(:name => pipeline.name, :locale => 'Internal')
  end
end

Factory.define :library_creation_pipeline do |p|
  p.name                  {|a| Factory.next :pipeline_name }
  p.automated             false
  p.active                true
  p.next_pipeline_id      nil
  p.previous_pipeline_id  nil
  p.location              {|location| location.association(:location)}

  p.after_build do |pipeline|
    pipeline.request_types << Factory(:request_type )
    pipeline.add_control_request_type
    pipeline.build_workflow(:name => pipeline.name, :locale => 'Internal')
  end
end

Factory.define :pulldown_library_creation_pipeline do |p|
  p.name                  {|a| Factory.next :pipeline_name }
  p.automated             false
  p.active                true
  p.next_pipeline_id      nil
  p.previous_pipeline_id  nil
  p.location              {|location| location.association(:location)}

  p.after_build do |pipeline|
    pipeline.request_types << Factory(:request_type )
    pipeline.add_control_request_type
    pipeline.build_workflow(:name => pipeline.name, :locale => 'Internal')
  end
end

Factory.define :task do |t|
  t.name                  "New task"
  t.workflow              {|workflow| workflow.association(:lab_workflow)}
  t.sorted                nil
  t.batched               nil
  t.location              ""
  t.interactive           nil
end

Factory.define :pipeline_admin, :class => User do |u|
  u.login         "ad1"
  u.email         {|a| "#{a.login}@example.com".downcase }
  u.workflow      {|workflow| workflow.association(:submission_workflow)}
  u.pipeline_administrator true
end

Factory.define :lab_workflow, :class => LabInterface::Workflow do |w|
  w.name                  {|a| Factory.next :lab_workflow_name }
  w.item_limit            2
  w.locale                "Internal"

  w.after_create do |workflow|
    workflow.pipeline = Factory(:pipeline, :workflow => workflow)
  end
end

Factory.define :batch_request do |br|
  br.batch                {|batch| batch.association(:batch)}
  br.request              {|request| request.association(:request)}
end

Factory.define :delayed_message do |dm|
  dm.message            "1"
  dm.queue_attempt_at   "#{Time.now}"
  dm.queue_name         "3"
end

Factory.define :request_information_type do |w|
  w.name                   ""
  w.key                    ""
  w.label                  ""
  w.hide_in_inbox          ""
end

Factory.define :pipeline_request_information_type do |prit|
  prit.pipeline                  {|pipeline| pipeline.association(:pipeline)}
  prit.request_information_type  {|request_information_type| request_information_type.association(:request_information_type)}
end

Factory.define :location do |l|
  l.name                   "Some fridge"
end


Factory.define :request_information do |ri|
  ri.request_id {|request| activity.association(:request)}
  ri.request_information_type_id {|request_information_type| activity.association(:request_information_type)}
  ri.value nil
end

Factory.define :implement do |i|
  i.name                "CS03"
  i.barcode             "LE6G"
  i.equipment_type      "Cluster Station"
end

Factory.define :robot do |robot|
  robot.name      "myrobot"
  robot.location  "lab"
end

Factory.define :robot_property do |p|
  p.name      "myrobot"
  p.value     "lab"
  p.key       "key_robot"
end

Factory.define :pico_set do |ps|
  ps.standard        {|asset| asset.association(:plate)}
  ps.pico_plate1     {|asset| asset.association(:plate)}
  ps.pico_plate2     {|asset| asset.association(:plate)}
  ps.stock           {|asset| asset.association(:plate)}
end

Factory.define :map do |a|
  a.description      "A2"
  a.asset_size       "96"
  a.location_id      2
  a.row_order        1
  a.column_order     8
end

Factory.define :plate_template do |p|
  p.name      "testtemplate"
  p.value     96
  p.size      96
end

Factory.define :asset_link do |a|
  a.ancestor_id     {|asset| asset.association(:asset)}
  a.descendant_id   {|asset| asset.association(:asset)}
end

Factory.define :tag do |t|
  t.oligo "AAA"
end

Factory.define :tag_group do |t|
  t.name "taggroup"
end

Factory.define :assign_tags_task do |t|
end

Factory.define :attach_infinium_barcode_task do |t|
end

Factory.define :tag_groups_task do |t|
end

Factory.define :gel_qc_task do |t|
end

Factory.define :empty_sample_tube, :class => SampleTube do |sample_tube|
  sample_tube.name                {|a| Factory.next :asset_name }
  sample_tube.value               ""
  sample_tube.descriptors         []
  sample_tube.descriptor_fields   ""
  sample_tube.qc_state            ""
  sample_tube.resource            nil
  sample_tube.barcode             {|a| Factory.next :barcode_number }
  sample_tube.purpose             Tube::Purpose.standard_sample_tube
end
Factory.define :sample_tube, :parent => :empty_sample_tube do |sample_tube|
  sample_tube.after_create do |sample_tube|
    sample_tube.aliquots.create!(:sample => Factory(:sample))
  end
end

Factory.define :cherrypick_task do |t|
  t.name                  "New task"
  t.pipeline_workflow_id      {|workflow| workflow.association(:lab_workflow)}
  t.sorted                nil
  t.batched               nil
  t.location              ""
  t.interactive           nil
end

Factory.define :assign_plate_purpose_task do |assign_plate_purpose_task|
  assign_plate_purpose_task.name "Assign a Purpose for Output Plates"
  assign_plate_purpose_task.sorted 3
end

Factory.define :plate_purpose do |plate_purpose|
  plate_purpose.name    "Frag"
end

Factory.define(:tube_purpose, :class => Tube::Purpose) do |purpose|
  purpose.name        'Tube purpose'
  purpose.target_type 'MultiplexedLibraryTube'
end

Factory.define :dilution_plate_purpose do |plate_purpose|
  plate_purpose.name    'Dilution'
end

Factory.define :barcode_prefix do |b|
  b.prefix  "DN"
end
