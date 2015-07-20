class AddSequencingSubmissionTemplates < ActiveRecord::Migration
  def self.submission_templates
    [
      "IHTP - HTP ISC - HiSeq 2500 Paired end sequencing",
      "IHTP - HTP ISC - HiSeq Paired end sequencing",
      "IHTP - HTP ISC - HiSeq v4 sequencing",
      "IHTP - HTP ISC - MiSeq sequencing",
      "IHTP - ISC Repool - HiSeq 2500 Paired end sequencing",
      "IHTP - ISC Repool - HiSeq Paired end sequencing",
      "IHTP - ISC Repool - HiSeq V4 Paired end sequencing",
      "IHTP - ISC Repool - MiSeq sequencing",
      "IHTP - Pooled MWGS - HiSeq 2500 Paired end sequencing",
      "IHTP - Pooled MWGS - HiSeq Paired end sequencing",
      "IHTP - Pooled MWGS - HiSeq v4 sequencing",
      "IHTP - Pooled MWGS - MiSeq sequencing",
      "IHTP - Pooled PWGS - HiSeq 2500 Paired end sequencing",
      "IHTP - Pooled PWGS - HiSeq Paired end sequencing",
      "IHTP - Pooled PWGS - HiSeq v4 sequencing",
      "IHTP - Pooled PWGS - MiSeq sequencing"
    ]
  end

  def self.up
    ActiveRecord::Base.transaction do
      self.submission_templates.map {|t| SubmissionTemplate.find_by_name(t)}.compact.each do |template|
        template_sequencing = template.clone
        template_sequencing.name.gsub!(/$/," - Only Sequencing")
        template_sequencing.submission_class_name = FlexibleSubmission.name
        # We select just the sequencing part of the submission template parameters. Normally it's the last request, but it could
        # be different CHECK BEFORE APPLYING
        template_sequencing.submission_parameters[:request_type_ids_list] = template_sequencing.submission_parameters[:request_type_ids_list].last
        template_sequencing.save!
      end
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      SubmissionTemplate.all.select{|st| st.name.match(/Only Sequencing/)}.each(&:destroy)
    end
  end
end
