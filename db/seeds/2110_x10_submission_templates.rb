ActiveRecord::Base.transaction do
  return
  outlines do |template|
    SubmissionTemplate.create!(template)
  end
      
  def outlines
    [
      {:pipeline=>'Illumina-A', :name => 'Pulldown WGS',    :infos=>'wgs',  :request_types=>['illumina_a_pulldown_wgs']},
        
      {:pipeline=>'Illumina-B', :name => 'Pooled HWGS',     :infos=>'was', :request_types=>['illumina_b_shared', 'illumina_b_pool'],   :role=>'ILB HWGS' },
      {:pipeline=>'Illumina-B', :name => 'Pippin HWGS',     :infos=>'was', :request_types=>['illumina_b_shared', 'illumina_b_pippin'], :role=>'ILB HWGS' }
    ].each do |outline|
      paras = {
          :input_field_infos => infos(outline[:infos]),
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
      yield(template)
    end
  end
      
  def infos(type)
    Hiseq2500Helper.input_fields(['150'],{
      'wgs'  => ["Standard"],
      'isc'  => ["Agilent Pulldown"],
      'full' => ["NlaIII gene expression","Standard","Long range","Small RNA","DpnII gene expression","qPCR only",
                "High complexity and double size selected","Illumina cDNA protocol","Custom","High complexity",
                "Double size selected","No PCR","Agilent Pulldown","ChiP-seq","Pre-quality controlled"]
      }[type])
  end

  def seq_x10_for(pipeline)
    @hash ||= Hash.new {|h,i| h[i]= [RequestType.find_by_key("#{i.underscore}_hiseq_xten_paired_end_sequencing").id]}
    @hash[pipeline]
  end
end