class FixRequestTypeOptions < ActiveRecord::Migration
  # we fix submission which have request options set to []. Should be nil or {}
  def self.up
    Submission.find_all_by_request_options("--- []\n\n").each do |submission|
      if submission.request_options.blank?
        submission.request_options = nil
        submission.save!
      else
        raise RuntimeError, "submission doesn't have blank request options"
      end
    end
  end

  def self.down
  end
end
