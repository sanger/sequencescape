class RemoveStudyFromRequest < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do
      add_column :submissions, :name, :string
      rename_column :requests, :study_id, :initial_study_id

      #At this point, submission have only one order, therefor one study
      #We set the study name has submission name
      ActiveRecord::Base.connection.execute <<-EOS
        UPDATE submissions s, studies st, orders o
        SET s.name = st.name
        WHERE s.id = o.submission_id
        AND o.study_id = st.id
    EOS
    end

  end

  def self.down

    ActiveRecord::Base.transaction do
      rename_column :requests, :initial_study_id, :study_id
      remove_column :submissions, :name
    end
  end
end
