class AddReadLength300ToExistingTemplates < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do
      SubmissionTemplate.find_all_by_name(templates).each do |template|
        sub_params = template.submission_parameters
        sub_params[:input_field_infos].each do |field|
          next unless field.display_name == "Read length"
          field.selection << "300"
        end
        template.update_attributes!(:submission_parameters => sub_params)
      end
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      SubmissionTemplate.find_all_by_name(templates).each do |template|
        sub_params = template.submission_parameters
        sub_params[:input_field_infos].each do |field|
          next unless field.display_name == "Read length"
          field.selection.delete("300")
        end
        template.update_attributes!(:submission_parameters => sub_params)
      end
    end
  end

  def self.templates
   [
      'Illumina-C - Library creation - MiSeq sequencing',
      'Illumina-C - Multiplexed library creation - MiSeq sequencing',
      'Illumina-C Cherrypicked - General PCR - MiSeq sequencing',
      'Illumina-C Cherrypicked - General no PCR - MiSeq sequencing',
      'Illumina-C General no PCR - MiSeq sequencing'
    ]
  end
end
