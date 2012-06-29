class Add250ReadLengthToMiseq < ActiveRecord::Migration
  def self.up
    SubmissionTemplate.find(:all, :conditions => 'name LIKE "%MiSeq%"').each do |submission_template|
      submission_template.submission_parameters[:input_field_infos].select do |variable|
        variable.ivars["display_name"] == "Read length"
      end.each do |variable|
        variable.ivars["parameters"][:selection]<<"250"
      end
      submission_template.save!
    end
  end

  def self.down
    SubmissionTemplate.find(:all, :conditions => 'name LIKE "%MiSeq%"').each do |submission_template|
      submission_template.submission_parameters[:input_field_infos].select do |variable|
        variable.ivars["display_name"] == "Read length"
      end.each do |variable|
        variable.ivars["parameters"][:selection].delete("250")
      end
      submission_template.save!
    end
  end
end
