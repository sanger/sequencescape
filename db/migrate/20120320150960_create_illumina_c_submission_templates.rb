class CreateIlluminaCSubmissionTemplates < ActiveRecord::Migration
  extend SubmissionTemplateMaker

  class << self
    def up
      ActiveRecord::Base.transaction do
        illumina_c = ProductLine.find_by_name('Illumina-C')

        mx_submission_templates.each { |old_template| make_new_templates!(illumina_c, old_template) }
      end
    end

    def mx_submission_templates
     @mx_templates ||= SubmissionTemplate.all(:conditions => ['name RLIKE ?', '^(Multiplexed )?Library Creation'])
    end

    def down
      ActiveRecord::Base.transaction do
        SubmissionTemplate.find(:all, :conditions => ["name like ?", 'Illumina-C - %']).each(&:destroy)
      end
    end
  end
end
