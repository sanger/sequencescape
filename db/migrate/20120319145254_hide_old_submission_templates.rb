class HideOldSubmissionTemplates < ActiveRecord::Migration

  # Return the id original multiplexed library creation request type
  def self.orig_req_id
    @orig_req_id ||= RequestType.find_by_key('multiplexed_library_creation').id
  end

  # This migration adds a flag to the submission_templates table and then hides
  # the submission templates originally used for Illumina-B submissions...
  def self.up
    add_column :submission_templates, :visible, :boolean, :null => false, :default => true

    ActiveRecord::Base.transaction do
      orig_templates = SubmissionTemplate.all.select do |template|
        template.submission_parameters[:request_type_ids_list].include?([orig_req_id])
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
