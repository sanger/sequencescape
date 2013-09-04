class AddIllaPippinNonPippin < ActiveRecord::Migration
 require 'hiseq_2500_helper'

  def self.up
    ActiveRecord::Base.transaction do
      new_templates.each do |new_st|
        each_variant(new_st) do |options|
          SubmissionTemplate.create!(options)
        end
      end
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      new_templates.each do |new_st|
        each_variant(new_st) do |options|
          SubmissionTemplate.find_by_name(options[:name]).destroy
        end
      end
    end
  end

  def self.new_templates
    [
      # {:middle_name => 'Pippin', :middle_request_types => [ [shared], [pippin] ] },
      {:middle_name => 'Pooled', :middle_request_types => [ [shared], [pooled] ] }
    ]
  end

  def self.each_variant(new_st)
    [true,false].each do |cherrypick|
      sequencing_requests.each do |sequencing_request|
        request_type_ids = cherrypick ? [[RequestType.find_by_key('cherrypick_for_illumina').id]] : []
        request_type_ids.concat(new_st[:middle_request_types]) << [request_type_id(sequencing_request)]
        yield({
          :name => "Illumina-A -#{cherrypick ? 'Cherrypicked -':''} #{new_st[:middle_name]} - #{sequencing_request[:name]}",
          :submission_class_name => 'LinearSubmission',
          :submission_parameters => {:request_type_ids_list => request_type_ids, :order_role_id => Order::OrderRole.find_or_create_by_role('ILA').id}.merge(sequencing_request[:submission_parameters]),
          :product_line => ProductLine.find_by_name('Illumina-A')
        })
      end
    end
  end

  def self.request_type_id(sequencing_request)
    # Horrible hack because out seeds are terrible
    RequestType.find_by_key(sequencing_request[:key].detect {|key| RequestType.find_by_key(key) }).id
  end

  def self.shared
    RequestType.find_by_key('illumina_a_shared').id
  end

  def self.pippin
    RequestType.find_by_key('illumina_a_pippin').id
  end

  def self.pooled
    RequestType.find_by_key('illumina_a_pool').id
  end

  def self.sequencing_requests
    [
      {:name=>'HiSeq 2500 Paired end sequencing', :key=>["illumina_a_hiseq_2500_paired_end_sequencing","hiseq_2500_paired_end_sequencing"], :submission_parameters => {:workflow_id=>1, :info_differential=>1}.merge(Hiseq2500Helper.other({:sub_params=>:ill_b})) },
      {:name=>'HiSeq 2500 Single end sequencing', :key=>["illumina_a_hiseq_2500_single_end_sequencing","hiseq_2500_single_end_sequencing"], :submission_parameters => {:workflow_id=>1, :info_differential=>1}.merge(Hiseq2500Helper.other({:sub_params=>:ill_b_single})) },

      {:name=>'HiSeq Paired end sequencing', :key=>["illumina_a_hiseq_paired_end_sequencing","hiseq_paired_end_sequencing"], :submission_parameters => {
        :workflow_id=>1,
        :input_field_infos => Hiseq2500Helper.input_fields(["50","75","100"],[
          "NlaIII gene expression","Standard","Long range","Small RNA","DpnII gene expression","qPCR only",
          "High complexity and double size selected","Illumina cDNA protocol","Custom","High complexity",
          "Double size selected","No PCR","Agilent Pulldown","ChiP-seq","Pre-quality controlled"
        ]) }
      },
      {:name=>'HiSeq Single ended sequencing', :key=>["illumina_a_single_ended_hi_seq_sequencing","single_ended_hi_seq_sequencing"], :submission_parameters => {:workflow_id=>1}.merge(Hiseq2500Helper.other({:sub_params=>:ill_b_single})) },
      {:name=>'Paired end sequencing', :key=>["illumina_a_paired_end_sequencing","paired_end_sequencing"], :submission_parameters => {:workflow_id=>1, :info_differential=>1} },
      {:name=>'Single ended sequencing', :key=>["illumina_a_single_ended_sequencing","single_ended_sequencing"], :submission_parameters => {:workflow_id=>1, :info_differential=>1} }
   ]
  end
end
