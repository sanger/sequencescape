#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2012 Genome Research Ltd.
class AddTransferRequestTypeForIlluminaATubes < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do
      tube_purpose = Tube::Purpose.find_by_name('Standard MX') or raise "Cannot find standard MX tube purpose"
      PlatePurpose.all(:conditions => { :name => Pulldown::PlatePurposes::PLATE_PURPOSE_FLOWS.map(&:last) }).each do |plate_purpose|
        plate_purpose.child_relationships.create!(:child => tube_purpose, :transfer_request_type => RequestType.transfer)
      end
    end
  end

  def self.down
    # Nothing to do here really
  end
end
