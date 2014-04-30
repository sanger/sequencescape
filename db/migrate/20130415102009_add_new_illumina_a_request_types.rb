class AddNewIlluminaARequestTypes < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do
      each_request_type do |request_type_options|
        say "Creating #{request_type_options[:name]}"
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
        :key => "illumina_a_shared",
        :name => "Illumina-A Shared Library Creation",
        :request_class_name => "IlluminaHtp::Requests::SharedLibraryPrep",
        :acceptable_plate_purposes => [Purpose.find_by_name('Cherrypicked')],
        :for_multiplexing => false,
        :no_target_asset => false
      },
      {
        :key => "illumina_a_isc",
        :name => "Illumina-A ISC",
        :request_class_name => "Pulldown::Requests::IscLibraryRequestPart",
        :acceptable_plate_purposes => [Purpose.find_by_name('Lib PCR-XP')],
        :for_multiplexing => true,
        :no_target_asset => false,
        :target_purpose => Purpose.find_by_name('Standard MX')
      }
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
