# frozen_string_literal: true

# These Cucumber features used seeded pipelines. RSpec deliberately truncates the
# seeds, so build the relevant records locally rather than loading global seeds.
module BatchFeatureHelpers
  def create_batch_feature_pipeline(name)
    name == 'Cherrypick' ? create_batch_cherrypick_pipeline : create_batch_miseq_pipeline
  end

  def create_batch_cherrypick_pipeline
    workflow = Workflow.create!(name: 'Cherrypick')
    create(:plate_template_task, workflow:)
    create(:cherrypick_task, workflow: workflow, name: 'Approve Plate Layout', batched: true, lab_activity: true)
    CherrypickPipeline
      .new(name: 'Cherrypick', active: true, sorter: 10, workflow: workflow,
           request_types: [create_batch_cherrypick_request_type])
      .add_control_request_type
      .tap(&:save!)
  end

  def create_batch_cherrypick_request_type
    create(
      :cherrypick_request_type,
      name: 'Cherrypick',
      key: 'cherrypick',
      order: 2,
      request_class: CherrypickForPulldownRequest
    )
  end

  def create_batch_miseq_pipeline
    SequencingPipeline
      .new(name: 'MiSeq sequencing', active: true, sorter: 2, workflow: create_batch_miseq_workflow,
           request_types: create_batch_miseq_request_types)
      .add_control_request_type
      .tap(&:save!)
  end

  def create_batch_miseq_request_types
    [nil, 'a', 'b', 'c'].map do |lab|
      create(
        :request_type,
        key: lab ? "illumina_#{lab}_miseq_sequencing" : 'miseq_sequencing',
        name: lab ? "Illumina-#{lab.upcase} MiSeq sequencing" : 'MiSeq sequencing',
        asset_type: 'LibraryTube',
        request_class: MiSeqSequencingRequest,
        multiples_allowed: false
      )
    end
  end

  def create_batch_miseq_workflow
    workflow = Workflow.create!(name: 'MiSeq sequencing', locale: 'External', item_limit: 1)
    {
      'Specify Dilution Volume' => [{ kind: 'Text', sorter: 1, name: 'Concentration' }],
      'Cluster Generation' => [
        { kind: 'Text', sorter: 1, name: 'Chip barcode' },
        { kind: 'Text', sorter: 2, name: 'Cartridge barcode' },
        { kind: 'Text', sorter: 4, name: 'Machine name' }
      ]
    }.each do |name, descriptor_attributes|
      create(
        :set_descriptors_task,
        workflow: workflow,
        name: name,
        sorted: 0,
        lab_activity: false,
        descriptor_attributes: descriptor_attributes
      )
    end
    workflow
  end

  def process_batch_submission_jobs(count)
    Delayed::Worker.new(quiet: true).work_off(count)
    errors = Delayed::Job.all.filter_map { |job| job.last_error if job.run_at? }.compact_blank
    expect(errors).to be_empty
    expect(Delayed::Job.count).to eq(0)
  end

  def visit_batch_pipeline(pipeline)
    visit pipeline_path(pipeline)
    expect(page).to have_current_path(pipeline_path(pipeline))
  end

  def create_batch_from_first_inbox_group
    check 'Include request 1'
    first(:select, 'Action to perform').select('Create Batch')
    first(:button, 'Submit').click
  end
end
