class FixRequestTypeOptions < ActiveRecord::Migration
  # we fix submission which have request options set to []. Should be nil or {}
  class Submission < ActiveRecord::Base ; set_table_name(:submissions) ; end
  
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
