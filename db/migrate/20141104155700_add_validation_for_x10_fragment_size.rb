#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2014,2015 Genome Research Ltd.
class AddValidationForX10FragmentSize < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do
      ['a', 'b'].each do |pipeline|
        rt = RequestType.find_by_key!("illumina_#{pipeline}_hiseq_x_paired_end_sequencing")
        RequestType::Validator.create!(:request_type => rt, :request_option=> "fragment_size_required_to", :valid_options=>['350'])
        RequestType::Validator.create!(:request_type => rt, :request_option=> "fragment_size_required_from", :valid_options=>['350'])
      end
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      ['a', 'b'].each do |pipeline|
        rt = RequestType.find_by_key!("illumina_#{pipeline}_hiseq_x_paired_end_sequencing")
        rt.request_type_validators.find_all_by_request_option(["fragment_size_required_from","fragment_size_required_to"]).each(&:destroy)
      end
    end
  end

end
