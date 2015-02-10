#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2012,2013 Genome Research Ltd.
class AddIulluminaCHiseq2500SubmissionTemplates < ActiveRecord::Migration

  require 'hiseq_2500_helper'

  def self.up
    ActiveRecord::Base.transaction do
      each_template do |settings|
        SubmissionTemplate.create!(Hiseq2500Helper.template(settings))
      end
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      each_template do |settings|
        SubmissionTemplate.find_by_name(settings[:name]).destroy
      end
    end
  end

  def self.each_template
    [
      {:name => "Illumina-C - Library creation - HiSeq 2500 Paired end sequencing", :library_creation => ['illumina_c_library_creation','library_creation'],
        :cherrypick=> false, :pipeline=>'c', :sub_params=>:ill_c},
      {:name => "Illumina-C - Multiplexed library creation - HiSeq 2500 Paired end sequencing", :library_creation => ['illumina_c_multiplexed_library_creation'],
        :cherrypick=> false, :pipeline=>'c', :sub_params=>:ill_c}
    ].each do |settings|
      yield settings
    end
  end

end
