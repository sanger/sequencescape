# frozen_string_literal: true

namespace :support do
  desc 'Disable the HiSeq submission templates'
  task disable_hiseq_submission_templates: :environment do
    # This task disables all HiSeq submission templates from the database because the HiSeq
    # platform is no longer used and the templates can cause accidental/incorrect submissions.
    templates_changed = 0
    ActiveRecord::Base.transaction do
      SubmissionTemplate.where('name LIKE ?', '%hiseq%').find_each do |submission_template|
        # Set the superceded_by_id to SUPERCEDED_BY_UNKNOWN_TEMPLATE (-2) to hide the template
        # This allows us to keep the template in case it needs to be restored
        submission_template.superceded_by_unknown! 
        submission_template.save!
        templates_changed += 1
      end
    end
    puts "Disabled #{templates_changed} HiSeq submission templates."
  end

  desc 'Enable the HiSeq submission templates'
  task enable_hiseq_submission_templates: :environment do
    # This task enables all HiSeq submission templates from the database.
    templates_changed = 0
    ActiveRecord::Base.transaction do
      SubmissionTemplate.where('name LIKE ?', '%hiseq%').find_each do |submission_template|
        # Set the superceded_by_id to LATEST_VERSION (-1) to show the template
        submission_template.superceded_by_id = SubmissionTemplate::LATEST_VERSION
        submission_template.save!
        templates_changed += 1
      end
    end
    puts "Enabled #{templates_changed} HiSeq submission templates."
  end
end
