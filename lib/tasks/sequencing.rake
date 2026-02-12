# frozen_string_literal: true

namespace :sequencing do
  desc 'Setting up sequencing pipelines'
  task setup: ['sequencing:novaseq:setup']

  desc 'Run to update descriptors. Can be removed once run'
  task update_descriptors: :environment do
    Descriptor.where(name: 'Operator').find_each(&:destroy)
    Task
      .where(workflow: Workflow.where(name: 'NovaSeq 6000 PE'), name: 'Read 1 & 2')
      .find_each { |task| task.descriptors.where(name: 'Pipette Carousel').find_each(&:destroy) }
  end
  task 'application:post_deploy' => 'sequencing:update_descriptors'

  namespace :novaseq do
    desc 'Setting up NovaSeq 6000 PE pipeline'
    task setup: :environment do
      # rubocop:todo Metrics/BlockLength
      ActiveRecord::Base.transaction do
        unless RequestType.exists?(key: 'illumina_htp_novaseq_6000_paired_end_sequencing')
          RequestType
            .create!(
              key: 'illumina_htp_novaseq_6000_paired_end_sequencing',
              name: 'Illumina-HTP NovaSeq 6000 Paired end sequencing',
              asset_type: 'LibraryTube',
              order: 2,
              initial_state: 'pending',
              request_class_name: 'NovaSeq6000PESequencingRequest',
              billable: true,
              product_line: ProductLine.find_by(name: 'Illumina-HTP'),
              request_purpose: :standard
            )
            .tap do |rt|
              RequestType::Validator.create!(
                request_type: rt,
                request_option: 'read_length',
                valid_options: [50, 75, 100, 150, 250]
              )
            end
        end
        unless SequencingPipeline.exists?(name: 'NovaSeq 6000 PE')
          SequencingPipeline.create!(
            name: 'NovaSeq 6000 PE',
            active: true,
            sorter: 10,
            max_size: 4,
            group_name: 'Sequencing',
            control_request_type_id: 0,
            min_size: 1
          ) do |pipeline|
            pipeline.request_types = RequestType.where(key: 'illumina_htp_novaseq_6000_paired_end_sequencing')
            pipeline
              .build_workflow(name: 'NovaSeq 6000 PE')
              .tap do |wf|
                AddSpikedInControlTask.create!(
                  name: 'Add Spiked in control',
                  sorted: 0,
                  lab_activity: true,
                  workflow: wf
                )
                SetDescriptorsTask.create!(name: 'Loading', sorted: 1, lab_activity: true, workflow: wf) do |task|
                  task.descriptors.build(
                    [
                      {
                        kind: 'Selection',
                        sorter: 3,
                        name: 'Workflow (Standard or Xp)',
                        selection: {
                          'Standard' => 'Standard',
                          'XP' => 'XP'
                        },
                        value: 'Standard'
                      },
                      { kind: 'Text', sorter: 4, name: 'DPX1' },
                      { kind: 'Text', sorter: 5, name: 'DPX2' },
                      { kind: 'Text', sorter: 6, name: 'DPX3' },
                      { kind: 'Text', sorter: 7, name: 'NovaSeq Xp Mainfold' },
                      { kind: 'Text', sorter: 8, name: 'Pipette Carousel' },
                      { kind: 'Text', sorter: 9, name: 'PhiX lot #' },
                      { kind: 'Text', sorter: 10, name: 'PhiX %' },
                      { kind: 'Text', sorter: 11, name: 'Lane loading concentration (pM)' },
                      { kind: 'Text', sorter: 12, name: 'Comment' }
                    ]
                  )
                end
                SetDescriptorsTask.create!(name: 'Read 1 & 2', sorted: 2, lab_activity: true, workflow: wf) do |task|
                  task.descriptors.build(
                    [{ kind: 'Text', sorter: 8, name: 'iPCR batch #' }, { kind: 'Text', sorter: 9, name: 'Comment' }]
                  )
                end
              end
            pipeline.request_information_types << RequestInformationType.where(
              label: 'Vol.',
              hide_in_inbox: false
            ).first!
            pipeline.request_information_types << RequestInformationType.where(
              label: 'Read length',
              hide_in_inbox: false
            ).first!
          end
        end
      end
      # rubocop:enable Metrics/BlockLength
    end
  end

  namespace :gbs_miseq do
    desc 'Setting up GBS MiSeq Request Type'
    task setup: :environment do
      ActiveRecord::Base.transaction do
        unless RequestType.find_by(key: 'gbs_miseq_sequencing')
          rt =
            RequestType.create!(
              key: 'gbs_miseq_sequencing',
              name: 'GBS MiSeq sequencing',
              asset_type: 'LibraryTube',
              initial_state: 'pending',
              order: 2,
              request_class_name: 'MiSeqSequencingRequest',
              billable: true,
              request_purpose: :standard
            )
          RequestType::Validator.create!(
            request_type: rt,
            request_option: 'read_length',
            valid_options: [25, 50, 130, 150, 250, 300]
          )
          SequencingPipeline.find_by(name: 'MiSeq sequencing').request_types << rt
        end
      end
    end
  end

  namespace :heron_miseq do
    desc 'Setting up Heron MiSeq Request Type'
    task setup: :environment do
      ActiveRecord::Base.transaction do
        unless RequestType.find_by(key: 'heron_miseq_sequencing')
          rt =
            RequestType.create!(
              key: 'heron_miseq_sequencing',
              name: 'Heron MiSeq sequencing',
              asset_type: 'LibraryTube',
              initial_state: 'pending',
              order: 2,
              request_class_name: 'MiSeqSequencingRequest',
              billable: true,
              request_purpose: :standard
            )
          RequestType::Validator.create!(
            request_type: rt,
            request_option: 'read_length',
            valid_options: [25, 50, 130, 150, 250, 300]
          )
          SequencingPipeline.find_by(name: 'MiSeq sequencing').request_types << rt
        end
      end
    end
  end
end
