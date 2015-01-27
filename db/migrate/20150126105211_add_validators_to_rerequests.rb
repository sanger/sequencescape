class AddValidatorsToRerequests < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do
      RequestType.find_by_key!('illumina_a_re_isc').tap do |rt|
        rt.library_types << LibraryType.find_by_name!('Agilent Pulldown')
        RequestType::Validator.create!(:request_type=>rt, :request_option=> "library_type", :valid_options=>RequestType::Validator::LibraryTypeValidator.new(rt.id))
      end
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      RequestType.find_by_key!('illumina_a_re_isc').tap do |rt|
        rt.library_types -= [LibraryType.find_by_name!('Agilent Pulldown')]
        rt.request_type_validators.find_by_name("library_type").destroy
      end
    end
  end
end
