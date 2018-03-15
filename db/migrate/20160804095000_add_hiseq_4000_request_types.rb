class AddHiseq4000RequestTypes < ActiveRecord::Migration
  class SubmissionWorkflow < ApplicationRecord
    self.table_name = 'submission_workflows'
  end

  def self.up
    ActiveRecord::Base.transaction do
      ['htp', 'c'].each do |pipeline|
        RequestType.create!(key: "illumina_#{pipeline}_hiseq_4000_paired_end_sequencing",
                            name: "Illumina-#{pipeline.upcase} HiSeq 4000 Paired end sequencing",
                            workflow_id: SubmissionWorkflow.find_by(key: 'short_read_sequencing').id,
                            asset_type: 'LibraryTube',
                            order: 2,
                            initial_state: 'pending',
                            request_class_name: 'HiSeqSequencingRequest',
                            billable: true,
                            product_line: ProductLine.find_by(name: "Illumina-#{pipeline.upcase}"),
                            request_purpose: :standard).tap do |rt|
          RequestType::Validator.create!(request_type: rt, request_option: 'read_length', valid_options: [150, 75])
        end
        RequestType.create!(key: "illumina_#{pipeline}_hiseq_4000_single_end_sequencing",
                            name: "Illumina-#{pipeline.upcase} HiSeq 4000 Single end sequencing",
                            workflow_id: SubmissionWorkflow.find_by(key: 'short_read_sequencing').id,
                            asset_type: 'LibraryTube',
                            order: 2,
                            initial_state: 'pending',
                            request_class_name: 'HiSeqSequencingRequest',
                            billable: true,
                            product_line: ProductLine.find_by(name: "Illumina-#{pipeline.upcase}"),
                            request_purpose: :standard).tap do |rt|
          RequestType::Validator.create!(request_type: rt, request_option: 'read_length', valid_options: [50])
        end
      end
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      ['htp', 'c'].each do |pipeline|
        RequestType.find_by(key: "illumina_#{pipeline}_hiseq_4000_paired_end_sequencing").destroy
        RequestType.find_by(key: "illumina_#{pipeline}_hiseq_4000_single_end_sequencing").destroy
      end
    end
  end
end
