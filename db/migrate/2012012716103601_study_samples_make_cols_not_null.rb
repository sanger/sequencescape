# 2012012716103600_study_samples_make_cols_not_null.rb

class StudySamplesMakeColsNotNull< ActiveRecord::Migration
def self.up
		execute "ALTER TABLE study_samples MODIFY column study_id int(11) NOT NULL";
		execute "ALTER TABLE study_samples MODIFY column sample_id int(11) NOT NULL";
  end

  def self.down
		execute "ALTER TABLE study_samples MODIFY column study_id int(11) DEFAULT NULL";
		execute "ALTER TABLE study_samples MODIFY column sample_id int(11) DEFAULT NULL";
  end
end

   
	
