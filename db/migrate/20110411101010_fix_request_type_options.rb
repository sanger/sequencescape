#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2011 Genome Research Ltd.
class FixRequestTypeOptions < ActiveRecord::Migration
  # we fix submission which have request options set to []. Should be nil or {}
  class Submission < ActiveRecord::Base ; self.table_name =(:submissions) ; end

  def self.up
    ActiveRecord::Base.transaction do
      Submission.find_all_by_request_options("--- []\n\n").each do |submission|
        if submission.request_options.blank?
          submission.request_options = nil
          submission.save!
        else
          puts "submission #{submission.id} doesn't have blank request options"
        end
      end
    end
  end

  def self.down
  end
end
