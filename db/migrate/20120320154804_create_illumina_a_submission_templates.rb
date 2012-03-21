class CreateIlluminaASubmissionTemplates < ActiveRecord::Migration
  def self.up
    SubmissionTemplate.find(:all, :conditions => ['name LIKE ? OR name LIKE ? OR name LIKE ?','Pulldown%', 'Cherrypick for pulldown%','Cherrypicking for pulldown -%']).each do |submission_template|
      submission_parameters = submission_template.submission_parameters.dup
      old_request_type = RequestType.find(submission_parameters[:request_type_ids_list].last.first)
      new_request_type = RequestType.find_by_key("illumina_a_#{old_request_type.key}")
      submission_parameters[:request_type_ids_list][-1] = [new_request_type.id]

      SubmissionTemplate.create!({
        :name => "Illumina-A - #{submission_template.name}",
        :submission_parameters => submission_parameters
      }.reverse_merge(submission_template.attributes).except!('created_at','updated_at'))

      submission_template.update_attributes(:visible=>false)
    end
  end

  def self.down
    SubmissionTemplate.find(:all, :conditions => ['name LIKE ?', 'Illumina-A - %']).each do |submission_template|
      submission_template.destroy!
    end
  end
end
