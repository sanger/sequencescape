class AddIllaPippinNonPippinRts < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do
      each_request_type do |request_type_options|
        RequestType.create!(shared_options.merge(request_type_options))
      end
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      each_request do |request_type_options|
        RequestType.find_by_key(request_type_options[:key]).destroy
      end
    end
  end

  def self.each_request_type
    [
      {
        :key => "illumina_a_pool",
        :name => "Illumina-a Pooled",
        :request_class_name => "IlluminaHtp::Requests::LibraryCompletion",
        :acceptable_plate_purposes => [Purpose.find_by_name!('Lib PCR-XP')],
        :for_multiplexing => true,
        :no_target_asset => false,
        :target_purpose => Purpose.find_by_name!('Lib Pool Norm')
      },
      {
        :key => "illumina_a_pippin",
        :name => "Illumina-A Pippin",
        :request_class_name => "IlluminaHtp::Requests::LibraryCompletion",
        :acceptable_plate_purposes => [Purpose.find_by_name('Lib PCR-XP')],
        :for_multiplexing => true,
        :no_target_asset => false,
        :target_purpose => Purpose.find_by_name!('Lib Pool SS-XP-Norm')
      },
    ].each do |request_type|
      yield request_type
    end
  end

  def self.shared_options
    {
        :workflow => Submission::Workflow.find_by_key('short_read_sequencing'),
        :asset_type => "Well",
        :order => 1,
        :initial_state => "pending",
        :billable => true,
        :product_line_id => ProductLine.find_by_name('Illumina-A'),
        :no_target_asset => false
    }
  end
end
