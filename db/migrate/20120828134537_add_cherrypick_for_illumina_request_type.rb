class AddCherrypickForIlluminaRequestType < ActiveRecord::Migration
  class << self
    def up
      ActiveRecord::Base.transaction do
        # Find the 'Illumina-A cherry pick for pulldown' request type
        new_request_type = old_request_type.clone

        new_request_type.tap do |new_request_type|
          # Duplicate request_type
          new_request_type.name = 'Cherrypick for Illumina'
          new_request_type.key  = 'cherrypick_for_illumina'
        end.save!

        # Add request type to pipeline
        cherrypick_pipeline.request_types << new_request_type


        # Deprecate the old request_type
        old_request_type.update_attributes(:deprecated => true)

        templates_using_request_type(old_request_type).each do |template|
          # The old cherrypick request_type is the first request_type on the
          # list, remove it...
          template.submission_parameters[:request_type_ids_list].shift

          # ...and update it to use the new type
          template.submission_parameters[:request_type_ids_list].unshift([new_request_type.id])

          template.save!
        end

      end
    end

    def cherrypick_pipeline
      @pipeline ||= Pipeline.find_by_name('Cherrypicking for Pulldown')
    end

    def old_request_type
      @old_request_type ||=
        RequestType.find_by_key('illumina_a_cherrypick_for_pulldown') or
          raise "Cannot find illumina_a_cherrypick_for_pulldown request type"
    end

    # Find submission_templates using the old request_type_id
    def templates_using_request_type(old_request_type)
      SubmissionTemplate.all.select { |template|
        template.submission_parameters[:request_type_ids_list].include?([old_request_type.id])
      }
    end

    def down
      ActiveRecord::Base.transaction do
        # Find the 'Illumina-A cherry pick for pulldown' request type
        # and UnDeprecate the old request_type
        old_request_type.update_attributes(:deprecated => false)

        new_request_type =
          RequestType.find_by_key('cherrypick_for_illumina') or
            raise "Cannot find cherrypick_for_illumina request type"

        templates_using_request_type(new_request_type).each do |template|
          template.submission_parameters[:request_type_ids_list].shift
          template.submission_parameters[:request_type_ids_list].unshift([old_request_type.id])

          template.save!
        end


        cherrypick_pipeline.request_types.delete(new_request_type)

        new_request_type.destroy

      end
    end
  end
end
