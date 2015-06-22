#This file is part of SEQUENCESCAPE; it is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2015 Genome Research Ltd.
class AddIscRerequest < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do
      RequestType.create!(
        :key=>'illumina_a_re_isc',
        :name=>'Illumina-A ReISC',
        :workflow=>Submission::Workflow.find_by_key('short_read_sequencing'),
        :asset_type => 'Well',
        :initial_state => 'pending',
        :order=>1,
        :request_class_name => 'Pulldown::Requests::IscLibraryRequest',
        :for_multiplexing => true,
        :product_line => ProductLine.find_by_name('Illumina-A'),
        :target_purpose => Purpose.find_by_name('Standard MX')
        ) do |rt|
        rt.acceptable_plate_purposes << Purpose.find_by_name!('Lib PCR-XP')
      end
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      RequestType.find_by_key!('illumina_a_re_isc').destroy
    end
  end
end
