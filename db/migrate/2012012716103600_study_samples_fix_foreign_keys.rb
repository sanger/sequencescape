class StudySamplesFixForeignKeys < ActiveRecord::Migration
def self.up
  	#execute "UPDATE study_samples SET study_id = (SELECT id FROM studies WHERE name = 'Example project') WHERE sample_id = 457";
		#execute "UPDATE study_samples SET sample_id = (SELECT id FROM samples WHERE name = 'Example sample') WHERE study_id  = 85";
    ActiveRecord::Base.transaction do
      StudySample.find_by_id(1).update_attributes!(:study_id => 85)
      StudySample.find_by_id(1119669).update_attributes(:sample_id => 457)
    end
  end

  def self.down
  	#execute "UPDATE study_samples SET study_id = 0 WHERE sample_id = 457";
		#execute "UPDATE study_samples SET sample_id = 0 WHERE study_id = 85";
    ActiveRecord::Base.transaction do
      StudySample.find_by_id(1).update_attributes!(:study_id => 0)
      StudySample.find_by_id(1119669).update_attributes!(:sample_id => 0)
    end
  end
end

   
	
