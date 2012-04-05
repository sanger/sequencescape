class CreateIlluminaBSubmissionTemplates < ActiveRecord::Migration
  class << self
    def up
      ActiveRecord::Base.transaction do
        mx_submission_templates.each do |submission_template|
          submission_parameters = submission_template.submission_parameters.dup

          submission_parameters[:request_type_ids_list] = new_request_types(submission_parameters[:request_type_ids_list])

          SubmissionTemplate.create!(
            {
              :name                  => "Illumina-B - #{submission_template.name}",
              :submission_parameters => submission_parameters,
              :visible               => true
            }.reverse_merge(submission_template.attributes).except!('created_at','updated_at')
          )
        end
      end
    end

    def new_request_type(old_request_type_id_arr)
      # Remember to pull the id out of the wrapping array...
      old_request_type = RequestType.find(old_request_type_id_arr.first)

        RequestType.find_by_key("illumina_b_#{old_request_type.key}")
    end

    def new_request_types(old_request_types_list)
      new_lib_request_type        = new_request_type(old_request_types_list.first)
      new_sequencing_request_type = new_request_type(old_request_types_list.last)

      [ [new_lib_request_type.id], [new_sequencing_request_type.id] ]
    end

    # Return the id original multiplexed library creation request type
    def orig_req_id
      @orig_req_id ||= RequestType.find_by_key('multiplexed_library_creation').id
    end

    def mx_submission_templates
      @mx_templates ||= SubmissionTemplate.all.select do |template|
        template.submission_parameters[:request_type_ids_list].include?([orig_req_id])
      end
    end

    def down
      ActiveRecord::Base.transaction do
        SubmissionTemplate.find(:all, :conditions => ["name like ?", 'Illumina-B - %']).each(&:destroy)
      end
    end
  end
end
