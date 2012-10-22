# Create Submission templates, using request types created in the Workflow seed file.
def list_combinations(llist)
  return [[]] if llist.size == 0
  llist = llist.clone
  l1 = llist.shift
  combinations = list_combinations(llist)
  ret = []
  l1.each do |e|
    combinations.each do |l|
      ret << ([e]+l)
    end
  end
  ret
end

def create_pulldown_submission_templates
  sequencing_request_type_names = [
    "Single ended sequencing",
    "Single ended hi seq sequencing",
    "Paired end sequencing",
    "HiSeq Paired end sequencing"
  ]

  pipelines_to_request_types = {
    'Illumina-A' => {
      'Pulldown WGS' => { 'library_type' => 'Standard',         'fragment_size_required_from' => 300, 'fragment_size_required_to' => 500 },
      'Pulldown SC'  => { 'library_type' => 'Agilent Pulldown', 'fragment_size_required_from' => 100, 'fragment_size_required_to' => 400 },
      'Pulldown ISC' => { 'library_type' => 'Agilent Pulldown', 'fragment_size_required_from' => 100, 'fragment_size_required_to' => 400 }
    },
  }

  workflow   = Submission::Workflow.find_by_key('short_read_sequencing') or raise StandardError, 'Cannot find Next-gen sequencing workflow'
  cherrypick = RequestType.find_by_name('Cherrypicking for Pulldown')    or raise StandardError, 'Cannot find Cherrypicking for Pulldown request type'

  pipelines_to_request_types.each do |pipeline,request_types_to_defaults|
    request_types_to_defaults.each do |request_type_name, defaults|
      pulldown_request_type = RequestType.find_by_name(request_type_name) or raise StandardError, "Cannot find #{request_type_name.inspect}"

      RequestType.find_each(:conditions => { :name => sequencing_request_type_names }) do |sequencing_request_type|
        submission                   = LinearSubmission.new
        submission.request_type_ids  = [ cherrypick.id, pulldown_request_type.id, sequencing_request_type.id ]
        submission.info_differential = workflow.id
        submission.workflow          = workflow
        submission.request_options   = defaults

        SubmissionTemplate.new_from_submission(
          "Cherrypick for pulldown - #{request_type_name} - #{sequencing_request_type.name}",
          submission
        ).tap { |template| template.superceded_by_unknown! }.save!

        SubmissionTemplate.new_from_submission("#{pipeline} - Cherrypick for pulldown - #{request_type_name} - #{sequencing_request_type.name}", submission).save!
      end
      RequestType.find_each(:conditions => { :name => sequencing_request_type_names }) do |sequencing_request_type|
        submission                   = LinearSubmission.new
        submission.request_type_ids  = [ pulldown_request_type.id, sequencing_request_type.id ]
        submission.info_differential = workflow.id
        submission.workflow          = workflow
        submission.request_options   = defaults

        SubmissionTemplate.new_from_submission("#{request_type_name} - #{sequencing_request_type.name}", submission).save!
      end
    end
  end
end

# The pulldown submissions
create_pulldown_submission_templates

# Now generate the rest of the submission templates
Submission::Workflow.all.each do |workflow|
  request_types_group = workflow.request_types.group_by {|rt| rt.order }.sort {|a, b| a[0] <=> b[0]  }
  request_type_ids_list = request_types_group.map { |o, rts| rts.map { |rt| rt.id } }

  if workflow.name =~ /[sS]equencing/
    combinations = list_combinations(request_type_ids_list)
    combinations.each do |request_type_ids|
      name = request_type_ids.map {|id| RequestType.find(id).name}.join(" - ")
      next if SubmissionTemplate.find_by_name(name)

      submission = LinearSubmission.new
      submission.request_type_ids = request_type_ids
      submission.info_differential = workflow.id
      submission.workflow = workflow

      SubmissionTemplate.new_from_submission(name, submission).save!
    end

  elsif workflow.name =~ /Microarray genotyping/
      [["DNA QC", "Cherrypick", "Genotyping"],
      ["DNA QC", "Cherrypick"],
      ["Cherrypick", "Genotyping"],
      ["DNA QC"],
      ["Cherrypick"]].each do |request_type_names|
        request_type_ids = request_type_names.map {|request_type_name| RequestType.find_by_name(request_type_name).id}
        name = request_type_names.join(" - ")

        submission = LinearSubmission.new
        submission.request_type_ids = request_type_ids
        submission.info_differential = workflow.id
        submission.request_options = { :initial_state => { request_type_ids.first => :pending }}
        submission.asset_input_methods   = [ 'select an asset group', 'enter a list of sample names found on plates' ]
        submission.workflow = workflow

        SubmissionTemplate.new_from_submission(name, submission).save!
      end
  end
end

# Submission templates that are needed and not automatically generated
microarray_submission_workflow = Submission::Workflow.find_by_name('Microarray genotyping') or raise StandardError, "Cannot find microarray genotyping workflow"
[
  { :name => 'Cherrypicking - Genotyping', :request_types => [ 'Cherrypick', 'Genotyping' ] },
  { :name => 'Microarray genotyping', :request_types => [ "DNA QC", 'Cherrypick', 'Genotyping' ] }
].each do |attributes|
  request_types = attributes[:request_types].map { |n| RequestType.find_by_name(n) or raise StandardError, "Request type #{n.inspect} not found" }
  SubmissionTemplate.new_from_submission(
    attributes[:name],
    LinearSubmission.new(
      :workflow              => microarray_submission_workflow,
      :request_options       => { :initial_state => { request_types.first.id => :pending } },
      :asset_input_methods   => [ 'select an asset group', 'enter a list of sample names found on plates' ],
      :request_type_ids_list => request_types.map(&:id).map { |x| [x] },
      :info_differential     => microarray_submission_workflow.id
    )
  ).save!
end


seq_submission_workflow = Submission::Workflow.find_by_name('Next-gen sequencing') or raise StandardError, "Cannot find seq_submission_workflow"
[
  { :name => "Cherrypicking for Pulldown", :request_types => [ 'Cherrypicking for Pulldown']},
  { :name => 'Cherrypicking for Pulldown - Pulldown Multiplex Library Preparation - HiSeq Paired end sequencing', :request_types => [ 'Cherrypicking for Pulldown', 'Pulldown Multiplex Library Preparation', 'HiSeq Paired end sequencing' ] },
  { :name => 'Cherrypicking for Pulldown - Pulldown Multiplex Library Preparation - Paired end sequencing', :request_types => [ 'Cherrypicking for Pulldown', 'Pulldown Multiplex Library Preparation', 'Paired end sequencing' ] }

].each do |attributes|
  request_types = attributes[:request_types].map { |n| RequestType.find_by_name(n) or raise StandardError, "Request type #{n.inspect} not found" }
  SubmissionTemplate.new_from_submission(
    attributes[:name],
    LinearSubmission.new(
      :asset_input_methods   => [ 'select an asset group', 'enter a list of sample names found on plates' ],
      :request_type_ids_list => request_types.map(&:id).map { |x| [x] },
      :info_differential     => seq_submission_workflow.id,
      :workflow              => seq_submission_workflow
    )
  ).save!
end



seq_submission_workflow = Submission::Workflow.find_by_name('Next-gen sequencing') or raise StandardError, "Cannot find seq_submission_workflow"
[
  { :name => 'PacBio', :request_types => ['PacBio Sample Prep','PacBio Sequencing']}

].each do |attributes|
  request_types = attributes[:request_types].map { |n| RequestType.find_by_name(n) or raise StandardError, "Request type #{n.inspect} not found" }
  submission = LinearSubmission.new(
    :asset_input_methods   => [ 'select an asset group', 'enter a list of sample names' ],
    :request_type_ids_list => request_types.map(&:id).map { |x| [x] },
    :info_differential     => seq_submission_workflow.id,
    :workflow              => seq_submission_workflow
  )
  insert_size = FieldInfo.new(:kind => "Selection", :key => "insert_size", :display_name => "Insert size", :default_value => "250", :selection => ["200","250","500","1000","2000","4000","6000","8000","10000"])
  sequencing_type = FieldInfo.new(:kind => "Selection", :key => "sequencing_type", :display_name => "Sequencing type", :default_value => "Standard", :selection => ["Standard","Strobe","Circular"])

  submission.set_input_field_infos([insert_size,sequencing_type])

  SubmissionTemplate.new_from_submission(
    attributes[:name],
    submission
  ).save!
end
