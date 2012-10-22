class AddNewIlluminaBSubmissionTemplates < ActiveRecord::Migration
  class << self
    def up
      ActiveRecord::Base.transaction do
        old_illumina_b_templates.each do |old_template|

          old_template.supercede do |new_template|
            new_template.name = new_template_name(old_template)

            # The request_type ids are individually wrapped in an array
            old_sequencescing_a = old_template.submission_parameters[:request_type_ids_list].last

            new_template.submission_parameters[:request_type_ids_list] = 
              (new_request_type_list << old_sequencescing_a)
          end

        end
      end
    end

    def down
      ActiveRecord::Base.transaction do
        new_illumina_b_templates.each(&:destroy)

        old_illumina_b_templates.each do |old_template|
          old_template.update_attributes!(:superceded_by_id => -1)
        end
      end
    end

    # Return a new array based on the cherrypicking and libray prep RequestTypes
    def new_request_type_list
      @new_request_type_list ||= [
        'cherrypick_for_illumina',
        'illumina_b_std'
      ].map { |key| [RequestType.find_by_key(key).id] }

      @new_request_type_list.dup
    end

    def old_illumina_b_templates
      SubmissionTemplate.find(:all,:conditions=>["name LIKE ?",'Illumina-B - Multiplexed Library Creation%'])
    end

    def new_illumina_b_templates
      SubmissionTemplate.find(:all,:conditions=>["name LIKE ?",'%Illumina-B - Cherrypicked - Multiplexed WGS%'])
    end

    def new_template_name(old_template)
      old_template.name.gsub(/Multiplexed library creation/,'Cherrypicked - Multiplexed WGS')
    end

  end
end
