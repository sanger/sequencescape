class CreateIlluminaASubmissionTemplates < ActiveRecord::Migration
  extend SubmissionTemplateMaker

  def self.up
    ActiveRecord::Base.transaction do
      illumina_a = ProductLine.find_by_name('Illumina-A')

      # Find the SubmissionTemplates you want to update...
      SubmissionTemplate.all(
        :conditions => ['name RLIKE ?', '[Pp]ulldown']
      ).each { |old_template| make_new_templates!(illumina_a, old_template) }
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      say 'Destroying Illumina-A SubmissionTemplates'
      SubmissionTemplate.all(:conditions => ['name LIKE ?', 'Illumina-A - %']).each(&:destroy)
    end
  end
end

