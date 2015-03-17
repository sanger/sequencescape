#This file is part of SEQUENCESCAPE; it is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2015 Genome Research Ltd.
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
