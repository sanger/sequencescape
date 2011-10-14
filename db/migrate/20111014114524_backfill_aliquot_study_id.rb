class BackfillAliquotStudyId < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do
      ActiveRecord::Base.connection.execute %Q{
    UPDATE aliquots al
    JOIN requests r ON (r.asset_id = al.receptacle_id)
    SET al.study_id = r.initial_study_id
    WHERE al.study_id IS NULL
    }
    end
  end

  def self.down
    raise ActiveRecord::IrreversibleMigration
  end
end
