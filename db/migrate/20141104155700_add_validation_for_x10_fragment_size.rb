class AddValidationForX10FragmentSize < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do
      ['a', 'b'].each do |pipeline|
        rt = RequestType.find_by_key("illumina_#{pipeline}_hiseq_x_paired_end_sequencing")
        RequestType::Validator.create!(:request_type => rt, :request_option=> "fragment_size_required_to", :valid_options=>['350'])
        RequestType::Validator.create!(:request_type => rt, :request_option=> "fragment_size_required_from", :valid_options=>['350'])
      end
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      ['a', 'b'].each do |pipeline|
        rt = RequestType.find_by_key("illumina_#{pipeline}_hiseq_x_paired_end_sequencing")
        rt.request_type_validators.find_all_by_request_option(["fragment_size_required_from","fragment_size_required_to"]).each(&:destroy)
      end
    end
  end

end
