class AddDefaultPreCapToIscTemplates < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do
      SubmissionTemplate.find(:all, :conditions => "name LIKE('% ISC %')").each do |submission_template|
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
