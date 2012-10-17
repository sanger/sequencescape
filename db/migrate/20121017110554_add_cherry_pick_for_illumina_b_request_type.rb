class AddCherryPickForIlluminaBRequestType < ActiveRecord::Migration
  class << self
    def up
      illumina_b_cherrypicked_templates.each do |template|
        replace_picking_rtype!(
          template,
          new_request_type
        ).save!
      end
    end

    def replace_picking_rtype!(template, new_picking_rtype)
      template.submission_parameters[:request_type_ids_list] =
        [ [new_picking_rtype.id] ] +
        template.submission_parameters[:request_type_ids_list][-2..-1]

      template
    end

    # Find old Illumina B SubmissionTemplates using using cherrypicking request type
    def illumina_b_cherrypicked_templates
      SubmissionTemplate.visible.all(:conditions => ['name like ?', 'Illumina-B - Cherrypicked - %'])
    end

    # Add a new request_type
    def new_request_type
      @new_request_type ||= old_request_type.clone.tap do |new_request_type|
        # Duplicate request_type
        new_request_type.name = 'Cherrypick for Illumina-B'
        new_request_type.key  = 'cherrypick_for_illumina_b'
        new_request_type.save!
      end
    end

    def old_request_type
      @old_request_type ||=
        RequestType.find_by_key('cherrypick_for_illumina') or
          raise "Cannot find cherrypick_for_pulldown request type"
    end

    def down
      illumina_b_cherrypicked_templates.each do |template|
        replace_picking_rtype!(
          template,
          old_request_type
        ).save!
      end

      RequestType.
        find_by_key('cherrypick_for_illumina_b').
        destroy
    end
  end
end
