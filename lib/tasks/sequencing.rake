# frozen_string_literal: true

namespace :sequencing do
  desc 'Creating all sequencing pipelines (only NovaSeq for now)'
  task setup: ['sequencing:novaseq:setup']

  namespace :novaseq do
    desc 'Setting up NovaSeq 6000 PE pipeline'
    task :setup do
      ActiveRecord::Base.transaction do
        unless RequestType.where(key: "illumina_htp_novaseq_6000_paired_end_sequencing").exists?
          RequestType.create!(key: "illumina_htp_novaseq_6000_paired_end_sequencing",
                              name: "Illumina-HTP NovaSeq 6000 Paired end sequencing",
                              asset_type: 'LibraryTube',
                              order: 2,
                              initial_state: 'pending',
                              request_class_name: 'HiSeqSequencingRequest',
                              billable: true,
                              product_line: ProductLine.find_by(name: "Illumina-HTP"),
                              request_purpose: :standard).tap do |rt|
            RequestType::Validator.create!(request_type: rt, request_option: 'read_length', valid_options: [150])
          end
        end
        unless SequencingPipeline.where(name: 'NovaSeq 6000 PE').exists?
          SequencingPipeline.create!(
            name: 'NovaSeq 6000 PE',
            asset_type: 'Lane',
            automated: false,
            active: true,
            sorter: 10,
            max_size: 4,
            group_name: 'Sequencing',
            control_request_type_id: 0,
            min_size: 1
          ) do |pipeline|
            pipeline.request_types = RequestType.where(key: 'illumina_htp_novaseq_6000_paired_end_sequencing')
            pipeline.build_workflow(name: 'NovaSeq 6000 PE').tap do |wf|
              build_tasks_for(wf, true)
            end
            add_information_types_to(pipeline)
          end
        end
      end
    end
  end
end


def build_tasks_for(workflow, paired_only = false)
  AddSpikedInControlTask.create!(name: 'Add Spiked in control', sorted: 0, workflow: workflow)
  SetDescriptorsTask.create!(name: 'Loading', sorted: 1, workflow: workflow) do |task|
    task.descriptors.build([
      { kind: 'Text', sorter: 1, name: 'Chip Barcode', required: true },
      { kind: 'Text', sorter: 2, name: 'Operator' },
      { kind: 'Text', sorter: 3, name: 'Workflow (Standard or Xp)' },
      { kind: 'Text', sorter: 4, name: 'DPX1' },
      { kind: 'Text', sorter: 5, name: 'DPX2' },
      { kind: 'Text', sorter: 6, name: 'DPX3' },
      { kind: 'Text', sorter: 7, name: 'NovaSeq Xp Mainfold' },
      { kind: 'Text', sorter: 8, name: 'Pipette Carousel' },
      { kind: 'Text', sorter: 9, name: 'PhiX lot #' },
      { kind: 'Text', sorter: 10, name: 'PhiX %' },
      { kind: 'Text', sorter: 11, name: 'Lane loading concentration (nM)' },
      { kind: 'Text', sorter: 12, name: 'Comment' }
    ])
  end

  SetDescriptorsTask.create!(name: 'Read 1', sorted: 2, workflow: workflow) do |task|
    task.descriptors.build([
      { kind: 'Text', sorter: 1, name: 'Chip Barcode', required: true },
      { kind: 'Text', sorter: 2, name: 'Operator' },
      { kind: 'Text', sorter: 3, name: 'Pipette Carousel' },
      { kind: 'Text', sorter: 4, name: 'Kit library tube' },
      { kind: 'Text', sorter: 5, name: 'Buffer cartridge' },
      { kind: 'Text', sorter: 6, name: 'Cluster cartridge' },
      { kind: 'Text', sorter: 7, name: 'SBS cartridge' },
      { kind: 'Text', sorter: 8, name: 'iPCR batch #' },
      { kind: 'Text', sorter: 9, name: 'Comment' }
    ])
  end

  SetDescriptorsTask.create!(name: 'Read 2', sorted: 2, workflow: workflow) do |task|
    task.descriptors.build([
      { kind: 'Text', sorter: 1, name: 'Chip Barcode' },
      { kind: 'Text', sorter: 2, name: 'Operator' },
      { kind: 'Text', sorter: 3, name: 'Pipette Carousel' },
      { kind: 'Text', sorter: 4, name: 'Kit library tube' },
      { kind: 'Text', sorter: 5, name: 'Buffer cartridge' },
      { kind: 'Text', sorter: 6, name: 'Cluster cartridge' },
      { kind: 'Text', sorter: 7, name: 'SBS cartridge' },
      { kind: 'Text', sorter: 8, name: 'iPCR batch #' },
      { kind: 'Text', sorter: 9, name: 'Comment' }
    ])
  end
end

def add_information_types_to(pipeline)
  pipeline.request_information_types << RequestInformationType.where(label: 'Vol.', hide_in_inbox: false).first!
  pipeline.request_information_types << RequestInformationType.where(label: 'Read length', hide_in_inbox: false).first!
end


