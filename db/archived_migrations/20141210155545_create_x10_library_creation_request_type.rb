#This file is part of SEQUENCESCAPE; it is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2015 Genome Research Ltd.
class CreateX10LibraryCreationRequestType < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do
      RequestType.create!(
        :name => "Illumina-HTP Library Creation",
        :key => "illumina_htp_library_creation",
        :workflow => Submission::Workflow.find_by_key!("short_read_sequencing"),
        :asset_type => "Well",
        :order => 1,
        :initial_state => "pending",
        :multiples_allowed => false,
        :request_class_name => "IlluminaHtp::Requests::LibraryCompletion",
        :morphology => 0,
        :for_multiplexing => true,
        :billable => false,
        :product_line => ProductLine.find_by_name!("Illumina-B")
      ).tap do |rt|
        rt.library_types << LibraryType.find_by_name!('Standard')
        rt.request_type_validators.create!(
          :request_option => 'library_type',
          :valid_options  => RequestType::Validator::LibraryTypeValidator.new(rt.id)
        )
      end
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      RequestType.find_by_key!("illumina_htp_library_creation").destroy
    end
  end
end
