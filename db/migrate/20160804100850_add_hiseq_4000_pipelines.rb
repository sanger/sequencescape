class AddHiseq4000Pipelines < ActiveRecord::Migration
  def up
    ActiveRecord::Base.transaction do
      SequencingPipeline.create!(
        name: 'HiSeq 4000 PE',
        asset_type: 'Lane',
        automated: false,
        active: true,
        location: cluster_formation_freezer,
        sorter: 10,
        max_size: 8,
        group_name: 'Sequencing',
        control_request_type_id: 0,
        min_size: 8
      ) do |pipeline|
        pipeline.request_types = RequestType.where("`key` LIKE 'illumina_%_hiseq_4000_paired_end_sequencing'")
        pipeline.build_workflow(name: 'HiSeq 4000 PE').tap do |wf|
          build_tasks_for(wf, true)
        end
        add_information_types_to(pipeline)
      end

      SequencingPipeline.create!(
        name: 'HiSeq 4000 SE',
        asset_type: 'Lane',
        automated: false,
        active: true,
        location: cluster_formation_freezer,
        sorter: 10,
        max_size: 8,
        group_name: 'Sequencing',
        control_request_type_id: 0,
        min_size: 8
      ) do |pipeline|
        pipeline.request_types = RequestType.where("`key` LIKE 'illumina_%_hiseq_4000_single_end_sequencing'")
        pipeline.build_workflow(name: 'HiSeq 4000 SE').tap do |wf|
          build_tasks_for(wf)
        end
        add_information_types_to(pipeline)
      end
    end
  end

  def down
    ActiveRecord::Base.transaction do
      SequencingPipeline.find_by(name: 'HiSeq 4000 PE').destroy
      SequencingPipeline.find_by(name: 'HiSeq 4000 SE').destroy
    end
  end

  def cluster_formation_freezer
    Location.find_by name: 'Cluster formation freezer'
  end

  def build_tasks_for(workflow, paired_only = false)
    AddSpikedInControlTask.create!(name: 'Add Spiked in control', sorted: 0, workflow: workflow)
    SetDescriptorsTask.create!(name: 'Cluster Generation', sorted: 1, workflow: workflow) do |task|
      task.descriptors.build([
        { kind: 'Text', sorter: 1, name: 'Chip Barcode', required: true },
        { kind: 'Text', sorter: 2, name: 'Operator' },
        { kind: 'Text', sorter: 3, name: 'Pipette Carousel #' },
        { kind: 'Text', sorter: 4, name: 'CBOT' },
        { kind: 'Text', sorter: 5, name: '-20 Temp. Read 1 Cluster Kit Lot #' },
        { kind: 'Text', sorter: 6, name: '-20 Temp. Read 1 Cluster Kit RGT #' },
        { kind: 'Text', sorter: 7, name: 'Pipette Carousel #' },
        { kind: 'Text', sorter: 8, name: 'Comment' }
      ])
    end

    SetDescriptorsTask.create!(name: 'Read 1 Lin/block/hyb/load', sorted: 2, workflow: workflow) do |task|
      task.descriptors.build([
        { kind: 'Text', sorter: 1, name: 'Chip Barcode', required: true },
        { kind: 'Text', sorter: 2, name: 'Operator' },
        { kind: 'Text', sorter: 3, name: 'Pipette Carousel #' },
        { kind: 'Text', sorter: 4, name: 'Sequencing Machine' },
        { kind: 'Text', sorter: 5, name: '-20 SBS Kit lot #' },
        { kind: 'Text', sorter: 6, name: '-20 SBS Kit RGT #' },
        { kind: 'Text', sorter: 7, name: '+4 SBS Kit lot #' },
        { kind: 'Text', sorter: 8, name: '+4 SBS Kit RGT #' },
        { kind: 'Text', sorter: 9, name: 'Incorporation Mix (HIM)' },
        { kind: 'Text', sorter: 10, name: 'SBS Buffer 1 (HB1)' },
        { kind: 'Text', sorter: 11, name: 'Scan Mix (HSM)' },
        { kind: 'Text', sorter: 12, name: 'SBS Buffer 2 (HB2)' },
        { kind: 'Text', sorter: 13, name: 'Cleavage Mix (HCM)' },
        { kind: 'Text', sorter: 14, name: 'iPCR batch #' },
        { kind: 'Text', sorter: 15, name: 'Comment' }
      ])
    end

    SetDescriptorsTask.create!(name: 'Read 2 Lin/block/hyb/load', sorted: 2, workflow: workflow) do |task|
      if paired_only
        task.descriptors.build([
          { kind: 'Text', sorter: 1, name: 'Operator' },
          { kind: 'Text', sorter: 2, name: 'Pipette Carousel #' },
          { kind: 'Text', sorter: 3, name: '-20 Temp. Read 1 Cluster Kit Lot #' },
          { kind: 'Text', sorter: 4, name: '-20 Temp. Read 1 Cluster Kit RGT #' },
          { kind: 'Text', sorter: 5, name: 'Resynthesis Mix (HRM)' },
          { kind: 'Text', sorter: 6, name: 'Linearization Mix 2 (HLM2)' },
          { kind: 'Text', sorter: 7, name: 'Amplification Mix (HAM)' },
          { kind: 'Text', sorter: 8, name: 'AMP premix (HDR)' },
          { kind: 'Text', sorter: 9, name: 'Denaturation Mix (HDR)' },
          { kind: 'Text', sorter: 10, name: 'Primer Mix Read 2 (HP11)' },
          { kind: 'Text', sorter: 11, name: 'Indexing Primer Mix (HP14)' },
          { kind: 'Text', sorter: 12, name: 'Comments' }
        ])
      else
        task.descriptors.build([
          { kind: 'Text', sorter: 1, name: 'Operator' },
          { kind: 'Text', sorter: 2, name: 'Pipette Carousel #' },
          { kind: 'Text', sorter: 3, name: '-20 Temp. Read 1 Cluster Kit Lot #' },
          { kind: 'Text', sorter: 4, name: '-20 Temp. Read 1 Cluster Kit RGT #' },
          { kind: 'Text', sorter: 5, name: 'Resynthesis Mix (HRM)' },
          { kind: 'Text', sorter: 6, name: 'Denaturation Mix (HDR)' },
          { kind: 'Text', sorter: 7, name: 'Index 1 Primer Mix (HP12)' },
          { kind: 'Text', sorter: 8, name: 'Comments' }
        ])
      end
    end
  end

  def add_information_types_to(pipeline)
    pipeline.request_information_types << RequestInformationType.where(label: 'Vol.', hide_in_inbox: false).first!
    pipeline.request_information_types << RequestInformationType.where(label: 'Read length', hide_in_inbox: false).first!
  end
end
