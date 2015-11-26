#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2014 Genome Research Ltd.
class AddPacbioCherrypickPipeline < ActiveRecord::Migration
  require 'control_request_type_creation'

  def self.up
    Pipeline.send(:include, ControlRequestTypeCreation)

    ActiveRecord::Base.transaction do

      liw = LabInterface::Workflow.create!(:name=>'PacBio Cherrypick')

      LabInterface::Workflow.find_by_name('Cherrypick').tasks.each do |task|
        # next if task.name == 'Set Location'
        new_task = task.dup
        new_task.workflow = liw
        new_task.save!
      end

      CherrypickPipeline.create!(
        :name => 'PacBio Cherrypick',
        :active => true,
        :automated=>false,
        :location_id => Location.find_by_name('PacBio library prep freezer'),
        :group_by_parent => true,
        :asset_type => 'Well',
        :group_name => 'R&D',
        :max_size => 3000,
        :sorter=>10,
        :request_types => [RequestType.find_by_key!('pacbio_cherrypick')],
        :workflow => liw
      ) do |pipeline|
        pipeline.add_control_request_type
      end
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      CherrypickPipeline.find_by_name('PacBio Cherrypick').destroy
      LabInterface::Workflow.find_by_name('PacBio Cherrypick').destroy
      RequestType.find_by_key('pacbio_cherrypick_control').destroy
    end
  end
end
