# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2015 Genome Research Ltd.

class CloneExistingMiseqPipeline < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do
      old_workflow = LabInterface::Workflow.find_by(name: 'MiSeq sequencing')
      old_workflow.deep_copy(' QC')
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      LabInterface::Workflow.find_by(name: 'MiSeq sequencing QC').tap do |workflow|
        workflow.pipeline.destroy
      end.destroy
    end
  end
end
