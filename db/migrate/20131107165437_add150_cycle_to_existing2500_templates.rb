class Add150CycleToExisting2500Templates < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do
      templates.each do |template|
        sub_params = template.submission_parameters
        sub_params[:input_field_infos].each do |field|
          next unless field.display_name == "Read length"
          field.selection << "150"
        end if sub_params[:input_field_infos].present?

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
          field.selection.delete("150")
        end
        template.update_attributes!(:submission_parameters => sub_params)
      end
    end
  end

  def self.templates
   SubmissionTemplate.find(:all, :conditions=>'name LIKE "%HiSeq 2500 Paired end sequencing"')
  end
end
