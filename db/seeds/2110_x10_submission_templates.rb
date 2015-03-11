#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2014,2015 Genome Research Ltd.
  outlines=
    [
      {:pipeline=>'Illumina-C', :name => 'General PCR',     :infos=>'wgs', :request_types=>['illumina_c_pcr'], :role=>'HSqX' }
    ].map do |outline|

      def seq_x10_for(pipeline)
        hash ||= Hash.new {|h,i| h[i]= [RequestType.find_by_key("illumina_b_hiseq_x_paired_end_sequencing").id]}
        hash[pipeline]
      end

      paras = {
          :request_type_ids_list => outline[:request_types].map {|rt| [RequestType.find_by_key!(rt).id] } << seq_x10_for(outline[:pipeline]),
          :workflow_id => 1
        }
      paras.merge({:order_role_id => Order::OrderRole.find_or_create_by_role(outline[:role]).id}) if outline[:role].present?
      template = {
        :name => "#{outline[:pipeline]} - #{outline[:name]} - HiSeq X 10 sequencing",
        :submission_class_name => 'LinearSubmission',
        :submission_parameters => paras,
        :product_line_id => ProductLine.find_by_name!(outline[:pipeline]).id
      }
      template
    end
 outlines.map do |template|
    SubmissionTemplate.create!(template)
  end

new_st = SubmissionTemplate.create!(
    :name => "HiSeq-X library creation and sequencing",
    :submission_class_name => 'FlexibleSubmission',
    :submission_parameters => {
      :order_role_id => Order::OrderRole.find_or_create_by_role('HSqX'),
      :request_type_ids_list => [
  'illumina_b_shared',
  'illumina_htp_library_creation',
  'illumina_htp_strip_tube_creation',
  'illumina_b_hiseq_x_paired_end_sequencing'
].map {|key| [RequestType.find_by_key!(key).id]},
      :workflow_id => Submission::Workflow.find_by_key("short_read_sequencing").id
    },
    :product_line_id => ProductLine.find_by_name!('Illumina-B').id
  )

SubmissionTemplate.create!(
        :name => "HiSeq-X library re-sequencing",
        :submission_class_name => 'FlexibleSubmission',
        :submission_parameters => {
          :order_role_id => Order::OrderRole.find_or_create_by_role('HSqX'),
          :request_type_ids_list => [
      'illumina_htp_strip_tube_creation',
      'hiseq_x_paired_end_sequencing'
    ].map {|key| [RequestType.find_by_key!(key).id]},
          :workflow_id => Submission::Workflow.find_by_key("short_read_sequencing").id
        },
        :product_line_id => ProductLine.find_by_name!('Illumina-B').id
      )

