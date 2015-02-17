#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2012 Genome Research Ltd.
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
