#This file is part of SEQUENCESCAPE; it is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2015 Genome Research Ltd.
class AddIscReRequestSubmissionTemplates < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do
      re_request = RequestType.find_by_key!('illumina_a_re_isc')
      sequencing_keys.each do |sequencing_key|
        sequencing_request = RequestType.find_by_key!(sequencing_key)
        SubmissionTemplate.create!(
          :name => "ISC Repool - #{sequencing_request.name.gsub('Illumina-A ','')}",
          :submission_class_name => 'LinearSubmission',
          :submission_parameters => {
            :request_type_ids_list => [[re_request.id],[sequencing_request.id]],
            :workflow_id => Submission::Workflow.find_by_key('short_read_sequencing').id,
            :order_role_id => Order::OrderRole.find_or_create_by_role('ReISC').id,
            :request_options => {'pre_capture_plex_level'=>8}
          },
          :product_line => ProductLine.find_by_name('Illumina-A')
        )
      end
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      re_request = RequestType.find_by_key!('illumina_a_re_isc')
      sequencing_keys.each do |sequencing_key|
        sequencing_request = RequestType.find_by_key!(sequencing_key)
        SubmissionTemplate.find_by_name!("ISC Repool - #{sequencing_request.name.gsub('Illumina-A ','')}").destroy
      end
    end
  end

  def self.sequencing_keys
    [
      'illumina_a_hiseq_paired_end_sequencing',
      'illumina_a_single_ended_hi_seq_sequencing',
      'illumina_a_hiseq_2500_paired_end_sequencing',
      'illumina_a_hiseq_2500_single_end_sequencing',
      'illumina_a_miseq_sequencing',
      'illumina_a_hiseq_v4_paired_end_sequencing'
    ]
  end
end
