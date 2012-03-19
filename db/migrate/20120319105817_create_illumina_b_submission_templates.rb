class CreateIlluminaBSubmissionTemplates < ActiveRecord::Migration
  class << self
    def illumina_b_pipeline
      @ill_c_pipeline ||= Pipeline.find_by_name('Illumina-B MX Library Preparation')
    end

    # Returns the last request_type added to the illumina_b pipeline
    def illumina_b_req_id
      @ill_b_req_id ||= illumina_b_pipeline.request_types.last.id
    end

    # Remove the Illumina-B MX libray prep request_id and replaces it with the Illumina-B MX request
    def new_request_type_ids(mx_template)
      [[illumina_b_req_id]] +
        mx_template.submission_parameters[:request_type_ids_list].
        delete_if { |rt_id_array| rt_id_array ==[orig_req_id]}
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

    def illu_b_submission_params(mx_template)
      {
        :request_type_ids_list => new_request_type_ids(mx_template)
      }.reverse_merge!(mx_template.submission_parameters)
    end

    def up
      ActiveRecord::Base.transaction do
        mx_submission_templates.each do |mx_template|

          SubmissionTemplate.create!(
            :name                  => "Illumina-B - #{mx_template.name}",
            :submission_class_name => 'LinearSubmission',
            :submission_parameters => illu_b_submission_params(mx_template)
          )
        end
      end
    end

    def down
      ActiveRecord::Base.transaction do
        SubmissionTemplate.find(:all, :conditions => ["name like ?", 'Illumina-B - %']).each(&:destroy)
      end
    end
  end
end
