#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2013 Genome Research Ltd.
class AddIlluminaCCherrypickPipeline < ActiveRecord::Migration
  require 'control_request_type_creation'

  def self.up
    Pipeline.send(:include, ControlRequestTypeCreation)

    ActiveRecord::Base.transaction do

      liw = LabInterface::Workflow.create!(:name=>'Illumina-C Cherrypick')

      LabInterface::Workflow.find_by_name('Cherrypick').tasks.each do |task|
        # next if task.name == 'Set Location'
        new_task = task.dup
        new_task.workflow = liw
        new_task.save!
      end

      CherrypickPipeline.create!(
        :name => 'Illumina-C Cherrypick',
        :active => true,
        :automated=>false,
        :location_id => Location.find_by_name('Library creation freezer'),
        :group_by_parent => true,
        :asset_type => 'Well',
        :group_name => 'Illumina-C Library creation',
        :max_size => 3000,
        :sorter=>10,
        :request_types => [RequestType.find_by_key!('illumina_c_cherrypick')],
        :workflow => liw
      ) do |pipeline|
        pipeline.add_control_request_type
      end
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      CherrypickPipeline.find_by_name('Illumina-C Cherrypick').destroy
      LabInterface::Workflow.find_by_name('Illumina-C Cherrypick').destroy
      RequestType.find_by_key('illumina_c_cherrypick_control').destroy
    end
  end
end
