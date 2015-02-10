#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2012 Genome Research Ltd.
class AddTubeToTubeBySubmissionTransferTemplate < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do
      TransferTemplate.create!(
        :name                => "Transfer from tube to tube by submission",
        :transfer_class_name => Transfer::BetweenTubesBySubmission.name
      )
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      TransferTemplate.find_by_name("Transfer from tube to tube by submission").destroy
    end
  end
end
