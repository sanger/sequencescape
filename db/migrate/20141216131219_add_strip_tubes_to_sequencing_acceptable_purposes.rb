class AddStripTubesToSequencingAcceptablePurposes < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do
      RequestType.find_by_key!('illumina_b_hiseq_x_paired_end_sequencing').acceptable_plate_purposes << PlatePurpose.find_by_name!('Strip Tube Purpose')
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      RequestType.find_by_key!('illumina_b_hiseq_x_paired_end_sequencing').acceptable_plate_purposes.clear
    end
  end
end
