class HideOldSubmissionTemplates < ActiveRecord::Migration

  KEYS_TO_HIDE = [
    'multiplexed_library_creation', 
    'library_creation'
  ]

  # Return the id original multiplexed library creation request type
  def self.orig_req_ids
    @orig_req_ids ||= RequestType.all(
      :conditions => ['`key` IN (?)', KEYS_TO_HIDE ]
    ).map(&:id).map(&:to_a)
  end

  # This migration adds a flag to the submission_templates table and then hides
  # the submission templates originally used for Illumina-B submissions...
  def self.up
    add_column :submission_templates, :visible, :boolean, :null => false, :default => true

    ActiveRecord::Base.transaction do
      orig_templates = SubmissionTemplate.all.reject do |template|
        (template.submission_parameters[:request_type_ids_list] & (orig_req_ids)).empty?
      end

      orig_templates.each do |template|
        say "Hiding original Illumina-B SubmissionTemplate: #{template.name}"
        template.update_attributes(:visible => false)
      end
    end
  end

  def self.down
    remove_column :submission_templates, :visible
  end
end
