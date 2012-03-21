class CreateMoreIlluminaCSubmissionTemplates < ActiveRecord::Migration
  # This migration should move the unplexed copy the unplexed submission
  # templates to the Illumina-C product line.
  def self.up
    ActiveRecord::Base.transaction do
      SubmissionTemplate.all(
        :conditions => ['name LIKE ?','Library creation%']
      ).each do |submission_template|
        submission_parameters = submission_template.submission_parameters
        old_request_type      = RequestType.find(submission_parameters[:request_type_ids_list][1].first)
        new_request_type      = RequestType.find_by_key("illumina_c_#{old_request_type.key}")
        submission_parameters[:request_type_ids_list][1] = [new_request_type.id]

        SubmissionTemplate.create!({
          :name                  => "Illumina-C - #{submission_template.name}",
          :submission_parameters => submission_parameters
        }.reverse_merge(submission_template.attributes).except!('created_at','updated_at'))

        submission_template.update_attributes(:visible => false)
      end
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      SubmissionTemplate.all(
        :conditions => ['name LIKE ?', 'Illumina-C - Library creation%']
      ).each(&:destroy)
    end
  end
end
