# 2012012716103600_study_sample_constraint_dml.rb
# samples and studies that have disappeared

class FixStudySamplesAddForeignKeys < ActiveRecord::Migration
def self.up
  	execute "UPDATE study_samples SET study_id = (select id from studies WHERE name = 'Dummy') WHERE study_id IN (4, 36)";
		execute "UPDATE study_samples SET sample_id = (select id from samples WHERE name = 'Example sample') WHERE sample_id IN (3396, 3447, 3448, 3466,  3467,  29775, 29777,  29779)";
		execute "ALTER TABLE study_samples MODIFY column study_id int(11) NOT NULL";
		execute "ALTER TABLE study_samples MODIFY column sample_id int(11) NOT NULL";
  end

  def self.down
		execute "ALTER TABLE study_samples MODIFY column study_id int(11) DEFAULT NULL";
		execute "ALTER TABLE study_samples MODIFY column sample_id int(11) DEFAULT NULL";
  	execute "UPDATE study_samples SET study_id = NULL WHERE study_id IN (4, 36)";
		execute "UPDATE study_samples SET sample_id = NULL WHERE sample_id IN (3396, 3447, 3448, 3466,  3467,  29775, 29777,  29779)";
  end
end

   
	
