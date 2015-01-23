class XtenStripTubeRequestType < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do
      rt=RequestType.create!({
        :key => "hiseq_x_paired_end_sequencing",
        :name => "HiSeq X Paired end sequencing",
        :workflow =>  Submission::Workflow.find_by_key("short_read_sequencing"),
        :asset_type => "Well",
        :order => 2,
        :initial_state => "pending",
        :request_class_name => "HiSeqSequencingRequest",
        :billable => true,
        :product_line => ProductLine.find_by_name("Illumina-B")
      })
      rt.acceptable_plate_purposes << PlatePurpose.find_by_name!('Strip Tube Purpose')
      RequestType::Validator.create!(:request_type => rt, :request_option=> "fragment_size_required_to", :valid_options=>['350','450'])
      RequestType::Validator.create!(:request_type => rt, :request_option=> "fragment_size_required_from", :valid_options=>['350','450'])
      RequestType::Validator.create!(:request_type => rt, :request_option=> "read_length", :valid_options=>[150])
      rt.library_types << LibraryType.find_by_name!('Standard')
      RequestType::Validator.create!(:request_type => rt, :request_option=> 'library_type', :valid_options  => RequestType::Validator::LibraryTypeValidator.new(rt.id))
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      request_type = RequestType.find_by_key("hiseq_x_paired_end_sequencing")
      request_type.destroy
    end
  end
end
