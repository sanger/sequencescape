#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2014 Genome Research Ltd.
class AddX10RequestTypeValidations < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do
      ['a', 'b'].each do |pipeline|
        rt = RequestType.find_by_key!("illumina_#{pipeline}_hiseq_x_paired_end_sequencing")
        RequestType::Validator.create!(:request_type => rt, :request_option=> "read_length", :valid_options=>[150])
        rt.library_types << LibraryType.find_by_name('Standard')
        RequestType::Validator.create!(:request_type=>rt, :request_option=> "library_type", :valid_options=>RequestType::Validator::LibraryTypeValidator.new(rt.id))
      end
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      ['a', 'b'].each do |pipeline|
        rt = RequestType.find_by_key!("illumina_#{pipeline}_hiseq_x_paired_end_sequencing")
        rt.request_type_validators.each(&:destroy)
        rt.library_types.clear
      end
    end
  end
end
