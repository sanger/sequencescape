#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2014 Genome Research Ltd.
class AddNoPoolingSubmissionTemplates < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do
      SubmissionTemplate.create!(
        :name => 'Illumina-C - General PCR - No multiplexing',
        :submission_class_name => 'LinearSubmission',
        :product_line => ProductLine.find_by_name('Illumina-C'),
        :submission_parameters => {
          :request_type_ids_list => [[RequestType.find_by_key('illumina_c_pcr_no_pool').id]],
          :workflow_id => Submission::Workflow.find_by_key('short_read_sequencing').id,
          :order_role_id => Order::OrderRole.find_by_role('PCR').id,
          :info_differential => 1
        }
      )
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      SubmissionTemplate.find_by_name('Illumina-C - General PCR - No multiplexing').destroy
    end
  end
end
