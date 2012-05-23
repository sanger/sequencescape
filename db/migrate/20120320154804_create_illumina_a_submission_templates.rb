class CreateIlluminaASubmissionTemplates < ActiveRecord::Migration
  extend SubmissionTemplateMaker

  def self.up
    ActiveRecord::Base.transaction do
      illumina_a = ProductLine.find_by_name('Illumina-A')

      # Find the SubmissionTemplates you want to update...
      SubmissionTemplate.all(
        :conditions => ['`name` RLIKE ?', 'Pulldown (WGS|SC|ISC)']
      ).each { |old_template| make_new_templates!(illumina_a, old_template) }


      # Hide the old Pulldown SubmissionTemplates
      SubmissionTemplate.all(
        :conditions => [
          '`name` RLIKE ? AND `name` NOT RLIKE ?',
          'Pulldown',
          'WGS|SC|ISC'
        ]
      ).each { |old_template| old_template.update_attributes(:visible => false)}
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      say 'Destroying Illumina-A SubmissionTemplates'
      SubmissionTemplate.all(:conditions => ['name LIKE ?', 'Illumina-A - %']).each(&:destroy)
    end
  end
end

