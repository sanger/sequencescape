class DummyTagsForMissingPools < ActiveRecord::Migration
# update aliquots set tag_id = 1090 where sample_id in (34868, 34869, 34870, 34871)

  class Aliquot < ActiveRecord::Base
    set_table_name('aliquots')

    DUMMY_TAG = 1090
    UNASSIGNED_TAG = -1

    def self.find_missing_pools_for_study_60()
      find_by_sql [" SELECT *  FROM aliquots WHERE sample_id IN (34868, 34869, 34870, 34871)"]
    end
  end

  def self.up
    ActiveRecord::Base.transaction do
      Aliquot.find_missing_pools_for_study_60.each do |aliquot, index|
          aliquot.update_attributes!(:tag_id => Aliquot::DUMMY_TAG)
        end
      end
  end

  def self.down
    ActiveRecord::Base.transaction do
      Aliquot.find_missing_pools_for_study_60.each do |aliquot, index|
          aliquot.update_attributes!(:tag_id => Aliquot::UNASSIGNED_TAG)
        end
      end
  end
end
