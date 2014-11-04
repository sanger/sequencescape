class AddValidationForX10FragmentSize < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do
      ['a', 'b'].each do |pipeline|
        rt = RequestType.find_by_key("illumina_#{pipeline}_hiseq_xten_paired_end_sequencing")
        RequestType::Validator.create!(:request_type => rt, :request_option=> "fragment_size_required_to", :valid_options=>[350])
        RequestType::Validator.create!(:request_type => rt, :request_option=> "fragment_size_required_from", :valid_options=>[350])
      end
    end
  end

  def self.down
  end

end