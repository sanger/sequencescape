class XtenStripTubePipeline < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do
      SequencingPipeline.create!(
        :name => "HiSeq X PE (spiked in controls) from strip-tubes",
        :automated => false,
        :active => true,
        :location => Location.find_by_name("Cluster formation freezer"),
        :group_by_parent => true,
        :asset_type => "Lane",
        :sorter => 9,
        :paginate => false,
        :max_size => 8,
        :min_size => 1,
        :summary => true,
        :group_name => "Sequencing",
        :control_request_type_id => 0
      ) do |pipeline|
        pipeline.workflow = LabInterface::Workflow.find_by_name!('HiSeq X PE (spiked in controls)').deep_copy(' from strip-tubes', true)
        pipeline.request_types = [RequestType.find_by_key('hiseq_x_paired_end_sequencing')]
      end
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      each_pipeline do |pipeline|
        Pipeline.find_by_name!("#{pipeline} from strip-tubes").tap do |pl|
          pl.workflow.destroy
        end.destroy
      end
    end
  end

end

