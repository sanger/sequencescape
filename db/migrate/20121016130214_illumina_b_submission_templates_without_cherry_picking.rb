#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2012 Genome Research Ltd.
class IlluminaBSubmissionTemplatesWithoutCherryPicking < ActiveRecord::Migration
  extend SubmissionTemplateMaker
  def self.up
    ActiveRecord::Base.transaction do
      illumina_b_templates = SubmissionTemplate.visible.all(:conditions => ['name like ?', 'Illumina-B - Cherrypicked %'])

      illumina_b_templates.map(&:dup).map do |template|
        raise "Submission Template should consist of 3 requests types" if
          template.submission_parameters[:request_type_ids_list].length != 3

        template.name = template.name.gsub(/- Cherrypicked /,'')

        template.submission_parameters[:request_type_ids_list] =
          template.submission_parameters[:request_type_ids_list][-2..-1]

        template
      end.each(&:save!)
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      templates_to_remove = SubmissionTemplate.visible.all(:conditions => ['name like ?', 'Illumina-B - Multiplexed WGS -%'])
      templates_to_remove.each(&:destroy)
    end
  end
end
