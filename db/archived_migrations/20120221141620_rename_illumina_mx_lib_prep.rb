#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2012 Genome Research Ltd.
class RenameIlluminaMxLibPrep < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do
      Pipeline.find_by_name('MX Library Preparation [NEW]').tap do |pipeline|
        pipeline.update_attributes(
          :name => 'Illumina-B MX Library Preparation'
        )
      end.workflow.update_attributes(:name => 'Illumina-B MX Library Preparation')
    end
  end

  def self.down
    say 'Renaming Illumina-B MX Library Preparation pipeline back to MX Library Preparation [NEW]'
    ActiveRecord::Base.transaction do
      Pipeline.find_by_name('Illumina-B MX Library Preparation').tap do |pipeline|
        pipeline.update_attributes(
          :name => 'MX Library Preparation [NEW]'
        )
      end.workflow.update_attributes(:name => 'New MX Library Preparation')
    end
  end
end
