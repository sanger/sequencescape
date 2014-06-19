class AddX10RequestTypeValidations < ActiveRecord::Migration
  def self.up
    ['a', 'b'].each do |pipeline|
      rt = RequestType.find_by_key("illumina_#{pipeline}_hiseq_xten_paired_end_sequencing")
      RequestType::Validator.create!(:request_type => rt, :request_option=> :read_length, :valid_options=>[150])
      RequestType::Validator.create!(:request_type=>rt, :request_option=>:read_length, :valid_options=>RequestType::Validator::LibraryTypeValidator.new(rt.id))
    end    
  end

  def self.down
  end
end
