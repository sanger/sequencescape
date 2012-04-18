class CreateIlluminaASubmissionTemplates < ActiveRecord::Migration

  def self.up
    ActiveRecord::Base.transaction do
      SubmissionTemplate.all(
        :conditions => ['name RLIKE ?', '[Pp]ulldown']
      ).each do |submission_template|
        submission_parameters = submission_template.submission_parameters.dup

        submission_parameters[:request_type_ids_list] = new_request_types(submission_parameters[:request_type_ids_list])

        SubmissionTemplate.create!(
          {
            :name                  => "Illumina-A - #{submission_template.name}",
            :submission_parameters => submission_parameters,
            :visible               => true
          }.reverse_merge(submission_template.attributes).except!('created_at','updated_at')
        )
      end
    end
  end

  def self.new_request_type(old_request_type_id_arr)
    # Remember to pull the id out of the wrapping array...
    old_request_type = RequestType.find(old_request_type_id_arr.first)

    RequestType.find_by_key("illumina_a_#{old_request_type.key}") or
      raise "New RequestType #{"illumina_a_#{old_request_type.key}"} not found"
  end

  def self.new_request_types(old_request_types_list)
    new_lib_request_type        = new_request_type(old_request_types_list.first)
    new_sequencing_request_type = new_request_type(old_request_types_list.last)

    [ [new_lib_request_type.id], [new_sequencing_request_type.id] ]
  end


  def self.down
    ActiveRecord::Base.transaction do
      SubmissionTemplate.all(:conditions => ['name LIKE ?', 'Illumina-A - %']).each(&:destroy)
    end
  end
end
