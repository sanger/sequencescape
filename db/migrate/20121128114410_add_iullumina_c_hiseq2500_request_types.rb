class AddIulluminaCHiseq2500RequestTypes < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do
      RequestType.create!(
          :key                => 'illumina_c_hiseq_2500_paired_end_sequencing',
          :name               => 'Illumina-C HiSeq 2500 Paired end sequencing',
          :workflow           => Submission::Workflow.find_by_key('short_read_sequencing'),
          :asset_type         => 'LibraryTube',
          :order              => 2,
          :initial_state      => 'pending',
          :multiples_allowed  => true,
          :request_class_name => 'HiSeqSequencingRequest',
          :product_line       => ProductLine.find_by_name('Illumina-C')
        )
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      RequestType.find_by_key('illumina_c_hiseq_2500_paired_end_sequencing').destroy
    end
  end
end
