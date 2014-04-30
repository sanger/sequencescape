class AddIlluminaAbMiseqRequestTypes < ActiveRecord::Migration

  # Deploy via deployment project

  def self.up
    ['Illumina-A','Illumina-B'].each do |pipeline|
      RequestType.create!(
        :key                =>"#{pipeline.underscore}_miseq_sequencing",
        :name               =>"#{pipeline} MiSeq sequencing",
        :workflow           => Submission::Workflow.find_by_key('short_read_sequencing'),
        :asset_type         => 'LibraryTube',
        :order              => 1,
        :initial_state      => 'pending',
        :multiples_allowed  => false,
        :request_class_name => "MiSeqSequencingRequest",
        :morphology         => 0,
        :for_multiplexing   => false,
        :billable           => true,
        :product_line       => ProductLine.find_by_name(pipeline),
        :deprecated         => false,
        :no_target_asset    => false
        ) do |rt|
        Pipeline.find_by_name('MiSeq sequencing').request_types << rt
      end
    end
  end

  def self.down
    ['Illumina-A','Illumina-B'].each do |pipeline|
      RequestType.find_by_name("#{pipeline} MiSeq sequencing").destroy
    end
  end
end
