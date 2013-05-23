class AddNewIlluminaBRequestTypes < ActiveRecord::Migration
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
        :key => "illumina_b_shared",
        :name => "Shared Library Creation",
        :request_class_name => "IlluminaHtp::Requests::SharedLibraryPrep",
        :acceptable_plate_purposes => [Purpose.find_by_name!('Cherrypicked')],
        :for_multiplexing => false,
        :no_target_asset => false
      },
      {
        :key => "illumina_b_pool",
        :name => "Illumina-B Pooled",
        :request_class_name => "IlluminaHtp::Requests::LibraryCompletion",
        :acceptable_plate_purposes => [Purpose.find_by_name!('Lib PCR-XP')],
        :for_multiplexing => true,
        :no_target_asset => false,
        :target_purpose => Purpose.find_by_name!('Lib Pool Norm')
      },
      {
        :key => "illumina_b_pippin",
        :name => "Illumina-B Pippin",
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
        :product_line_id => ProductLine.find_by_name('Illumina-B'),
        :no_target_asset => false
    }
  end
end
