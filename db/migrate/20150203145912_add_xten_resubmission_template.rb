#This file is part of SEQUENCESCAPE; it is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2015 Genome Research Ltd.
class AddXtenResubmissionTemplate < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do
      new_st = SubmissionTemplate.create!(
        :name => "HiSeq-X library re-sequencing",
        :submission_class_name => 'FlexibleSubmission',
        :submission_parameters => {
          :order_role_id => Order::OrderRole.find_or_create_by_role('HSqX'),
          :request_type_ids_list => request_types,
          :workflow_id => Submission::Workflow.find_by_key("short_read_sequencing").id
        },
        :product_line_id => ProductLine.find_by_name!('Illumina-B').id
      )
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      SubmissionTemplate.find_by_name!("HiSeq-X library re-sequencing").destroy
    end
  end

  def self.request_types
    [
      'illumina_htp_strip_tube_creation',
      'hiseq_x_paired_end_sequencing'
    ].map {|key| [RequestType.find_by_key!(key).id]}
  end
end
