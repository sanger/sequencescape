class AddAcceptiblePlatePurposesToNewPipelines < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do
      ['WGS','SC','ISC'].each do |pipeline|
        request_type = RequestType.find_by_key("illumina_a_pulldown_#{pipeline.downcase}")
        plate_purpose = PlatePurpose.find_by_name("#{pipeline} stock DNA")
        request_type.acceptable_plate_purposes << plate_purpose
      end
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      ['WGS','SC','ISC'].each do |pipeline|
        request_type = RequestType.find_by_key("illumina_a_pulldown_#{pipeline.downcase}")
        plate_purpose = PlatePurpose.find_by_name("#{pipeline} stock DNA")
        request_type.acceptable_plate_purposes.delete(plate_purpose)
      end

    end
  end
end
