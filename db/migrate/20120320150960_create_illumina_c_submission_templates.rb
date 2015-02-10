#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2012 Genome Research Ltd.
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
