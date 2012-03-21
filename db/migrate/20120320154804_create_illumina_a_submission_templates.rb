class CreateIlluminaASubmissionTemplates < ActiveRecord::Migration
  def self.up
    SubmissionTemplate.find(:all, :conditions => ['name LIKE ?','Pulldown%']).each do |submission_template|
      submission_parameters = submission_template.submission_parameters
      old_request_type = RequestType.find(submission_parameters[:request_type_ids_list][1].first)
      new_request_type = RequestType.find_by_key("illumina_a_#{old_request_type.key}")
      submission_parameters[:request_type_ids_list][1] = [new_request_type.id]

      SubmissionTemplate.create!({
        :name => "Illumina-A - #{submission_template.name}",
        :submission_parameters => submission_parameters
      }.reverse_merge(submission_template.attributes).except!('created_at','updated_at'))

      submission_template.update_attributes(:visible=>false)
    end
  end

  def self.down
    SubmissionTemplate.find(:all, :conditions => ['name LIKE ?', 'Illumina-A - Pulldown%']).each do |submission_template|
      submission_template.destroy
    end
  end
end
