class AddX10RequestType < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do
      ['a', 'b'].each do |pipeline|
        RequestType.create!({
          :key => "illumina_#{pipeline}_hiseq_xten_paired_end_sequencing",
          :name => "Illumina-#{pipeline.upcase} HiSeq X Ten Paired end sequencing",
          :workflow =>  Submission::Workflow.find_by_key("short_read_sequencing"),
          :asset_type => "LibraryTube",
          :order => 2,
          :initial_state => "pending",
          :request_class_name => "HiSeqSequencingRequest",
          :billable => true,
          :product_line => ProductLine.find_by_name("Illumina-#{pipeline.upcase}")
        })
      end
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      ['a', 'b'].each do |pipeline|
        RequestType.find_by_key("illumina_#{pipeline}_hiseq_x_ten_paired_end_sequencing").destroy
      end
    end
  end
end
