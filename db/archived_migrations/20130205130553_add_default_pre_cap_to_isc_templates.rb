#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2013 Genome Research Ltd.
class AddDefaultPreCapToIscTemplates < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do
      SubmissionTemplate.find(:all, :conditions => "name LIKE('% ISC %')").each do |submission_template|
        submission_template.submission_parameters[:request_options]||={}
        submission_template.submission_parameters[:request_options]['pre_capture_plex_level']='8'
        submission_template.save
      end
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      SubmissionTemplate.find(:all, :conditions => "name LIKE('% ISC %')").each do |submission_template|
        submission_template.submission_parameters[:request_options].delete('pre_capture_plex_level')
        submission_template.save
      end
    end
  end
end
