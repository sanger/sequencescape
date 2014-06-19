ActiveRecord::Base.transaction do
  def outlines
    [
    {:pipeline=>'Illumina-A', :name => 'Pulldown WGS',    :infos=>'wgs',  :request_types=>['illumina_a_pulldown_wgs']},
    {:pipeline=>'Illumina-A', :name => 'Pulldown SC',     :infos=>'isc',  :request_types=>['illumina_a_pulldown_sc']},
    {:pipeline=>'Illumina-A', :name => 'Pulldown ISC',    :infos=>'isc',  :request_types=>['illumina_a_pulldown_isc']},
    {:pipeline=>'Illumina-A', :name => 'Pooled',          :infos=>'full', :request_types=>['illumina_a_shared','illumina_a_pool'],    :role=>'ILA'},
    {:pipeline=>'Illumina-A', :name => 'HTP ISC',         :infos=>'isc',  :request_types=>['illumina_a_isc'],                         :role=>'ILA ISC'},

    {:pipeline=>'Illumina-B', :name => 'Multiplexed WGS', :infos=>'full', :request_types=>['illumina_b_std']},
    {:pipeline=>'Illumina-B', :name => 'Pooled PATH',     :infos=>'full', :request_types=>['illumina_b_shared', 'illumina_b_pool'],   :role=>'ILB PATH'},
    {:pipeline=>'Illumina-B', :name => 'Pooled HWGS',     :infos=>'full', :request_types=>['illumina_b_shared', 'illumina_b_pool'],   :role=>'ILB HWGS' },
    {:pipeline=>'Illumina-B', :name => 'Pippin PATH',     :infos=>'full', :request_types=>['illumina_b_shared', 'illumina_b_pippin'], :role=>'ILB PATH'},
    {:pipeline=>'Illumina-B', :name => 'Pippin HWGS',     :infos=>'full', :request_types=>['illumina_b_shared', 'illumina_b_pippin'], :role=>'ILB HWGS' },
      
    {:pipeline=>'Illumina-C', :name => 'General PCR',     :infos=>'full', :request_types=>['illumina_c_pcr'], :role=>'PCR' },
    {:pipeline=>'Illumina-C', :name => 'General no PCR',     :infos=>'full', :request_types=>['illumina_c_nopcr'], :role=>'PCR' },
    {:pipeline=>'Illumina-C', :name => 'Library Creation',     :infos=>'full', :request_types=>['illumina_c_library_creation'], :role=>'ILC' },
    {:pipeline=>'Illumina-C', :name => 'Multiplexed Library Creation',     :infos=>'full', :request_types=>['illumina_c_multiplexed_library_creation'], :role=>'ILC' }
      
    ].each do |outline|
      paras = {
          :input_field_infos => infos(outline[:infos]),
          :request_type_ids_list => outline[:request_types].map {|rt| [RequestType.find_by_key!(rt).id] } << seq_v4_for(outline[:pipeline]),
          :workflow_id => 1
        }
      paras.merge({:order_role_id => Order::OrderRole.find_or_create_by_role(outline[:role]).id}) if outline[:role].present?
      template = {
        :name => "#{outline[:pipeline]} - #{outline[:name]} - HiSeq v4 sequencing",
        :submission_class_name => 'LinearSubmission',
        :submission_parameters => paras,
        :product_line_id => ProductLine.find_by_name!(outline[:pipeline]).id
      }
      yield(template)
    end
  end
      
  def infos(type)
    Hiseq2500Helper.input_fields(['75', '125'],{
      'wgs'  => ["Standard"],
      'isc'  => ["Agilent Pulldown"],
      'full' => ["NlaIII gene expression","Standard","Long range","Small RNA","DpnII gene expression","qPCR only",
                "High complexity and double size selected","Illumina cDNA protocol","Custom","High complexity",
                "Double size selected","No PCR","Agilent Pulldown","ChiP-seq","Pre-quality controlled"]
      }[type])
  end

  def seq_v4_for(pipeline)
    @hash ||= Hash.new {|h,i| h[i]= [RequestType.find_by_key("#{i.underscore}_hiseq_v4_paired_end_sequencing").id]}
    @hash[pipeline]
  end
  
  outlines do |template|
    SubmissionTemplate.create!(template)
  end
        
end