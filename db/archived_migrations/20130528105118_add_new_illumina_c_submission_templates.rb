#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2013 Genome Research Ltd.
class AddNewIlluminaCSubmissionTemplates < ActiveRecord::Migration

  def self.templates
    [
      {:name=>'General PCR',     :role=>'PCR',   :type=>'illumina_c_pcr'},
      {:name=>'General no PCR',  :role=>'PCR',   :type=>'illumina_c_nopcr'}
    ]
  end

  def self.up
    ActiveRecord::Base.transaction do
      templates.each do |options|
        IlluminaC::Helper::TemplateConstructor.new(options).build!
      end
    end
  end

  def self.down
    templates.each do |t|
      IlluminaC::Helper::TemplateConstructor.find_for(t[:name]).each {|st| st.destroy }
    end
  end
end
