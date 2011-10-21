class BackfillAliquotStudyViaSample < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do
      ActiveRecord::Base.connection.execute %(
      UPDATE aliquots AS al
      JOIN study_samples AS ss
        ON (al.sample_id = ss.sample_id)
      SET al.study_id=ss.study_id
      WHERE al.study_id IS NULL;
)
    end
  end

  def self.down
  end
end
