class CreateIlluminaBSubmissionTemplates < ActiveRecord::Migration
  extend SubmissionTemplateMaker
  class << self
    def up
      ActiveRecord::Base.transaction do
        illumina_b = ProductLine.find_by_name('Illumina-B')

        mx_submission_templates.each { |old_template| make_new_templates!(illumina_b, old_template) }
      end
    end

    # Return the id original multiplexed library creation request type
    def orig_req_id
      @orig_req_id ||= RequestType.find_by_key('multiplexed_library_creation').id
    end

    def mx_submission_templates
      @mx_templates ||= SubmissionTemplate.all.select do |template|
        template.submission_parameters[:request_type_ids_list].include?([orig_req_id])
      end.reject {|t| t.name =~ /MiSeq/}
    end

    def down
      ActiveRecord::Base.transaction do
        SubmissionTemplate.find(:all, :conditions => ["name like ?", 'Illumina-B - %']).each(&:destroy)
      end
    end
  end
end
