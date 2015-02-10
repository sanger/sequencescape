#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2014 Genome Research Ltd.
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


  outlines.each do |template|
    SubmissionTemplate.create!(template)
  end
