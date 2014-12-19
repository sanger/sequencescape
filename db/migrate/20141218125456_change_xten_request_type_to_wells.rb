class ChangeXtenRequestTypeToWells < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do
      each_type do |key|
        RequestType.find_by_key(key).update_attributes!(:asset_type=>'Well')
      end
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      each_type do |key|
        RequestType.find_by_key(key).update_attributes!(:asset_type=>'LibraryTube')
      end
    end
  end

  def self.each_type
    ['illumina_a_hiseq_x_paired_end_sequencing','illumina_b_hiseq_x_paired_end_sequencing'].each {|t| yield t }
  end
end
