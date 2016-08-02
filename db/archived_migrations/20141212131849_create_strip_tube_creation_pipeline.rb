#This file is part of SEQUENCESCAPE; it is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2015 Genome Research Ltd.
class CreateStripTubeCreationPipeline < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do
      StripTubeCreationPipeline.create!(
        :name => 'Strip Tube Creation',
        :automated => false,
        :active => true,
        :location => Location.find_by_name('Cluster formation freezer'),
        :group_by_parent => true,
        :sorter => 8,
        :paginate => false,
        :max_size => 96,
        :min_size => 8,
        :summary => true,
        :externally_managed => false,
        :control_request_type_id => 0,
        :group_name => 'Sequencing'
      ) do |pipeline|
        pipeline.request_types << RequestType.find_by_key!('illumina_htp_strip_tube_creation')
        pipeline.workflow = LabInterface::Workflow.create!(:name=>'Strip Tube Creation')
      end
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      StripTubeCreationPipeline.find_by_name!('Strip Tube Creation').destroy
    end
  end
end
