#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2011 Genome Research Ltd.
class ChangeMxLibPrepCharTask < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do
      say("Changing the class used for Mx Library Pipeline Characterisation to SetCharacterisationDescriptorsTask")
    
      mx_library_prep_pipeline = LabInterface::Workflow.find_by_name("New MX Library Preparation")
      characterisation_task = mx_library_prep_pipeline.tasks.select { |t| t.name == "Characterisation" }.first
    
      characterisation_task.sti_type = "SetCharacterisationDescriptorsTask"

      characterisation_task.save!
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      say("Changing the class used for Mx Library Pipeline Characterisation back to SetDescriptorsTask")
    
      mx_library_prep_pipeline = LabInterface::Workflow.find_by_name("New MX Library Preparation")
      characterisation_task = mx_library_prep_pipeline.tasks.select { |t| t.name == "Characterisation" }.first
    
      characterisation_task.sti_type = "SetDescriptorsTask"
    
      characterisation_task.save!
    end
  end
end
