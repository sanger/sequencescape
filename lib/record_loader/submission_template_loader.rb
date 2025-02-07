# frozen_string_literal: true
# This file was automatically generated via `rails g record_loader`

# RecordLoader handles automatic population and updating of database records
# across different environments
# @see https://rubydoc.info/github/sanger/record_loader/
module RecordLoader
  # Creates the specified submission templates if they are not present
  class SubmissionTemplateLoader < ApplicationRecordLoader
    config_folder 'submission_templates'

    def create_or_update!(name, options)
      derived_options = generate_derived_options(options['related_records'])
      final_options = options.except('related_records').merge(derived_options)

      SubmissionTemplate.create_with(final_options).find_or_create_by!(name:)
    end

    def generate_derived_options(related_records)
      {
        product_line: ProductLine.find_or_create_by!(name: related_records['product_line_name']),
        product_catalogue: ProductCatalogue.find_by!(name: related_records['product_catalogue_name']),
        submission_parameters: submission_parameters(related_records)
      }
    end

    # rubocop:disable Metrics/AbcSize
    def submission_parameters(related_records)
      params = {}
      params[:request_type_ids_list] = sort_request_type_ids(related_records['request_type_keys']) if related_records[
        'request_type_keys'
      ]
      params[:order_role_id] = find_order_role(related_records['order_role']).id if related_records['order_role']
      params[:project_id] = find_project(related_records['project_name']).id if related_records['project_name']
      params[:study_id] = find_study(related_records['study_name']).id if related_records['study_name']
      params
    end

    # rubocop:enable Metrics/AbcSize

    def sort_request_type_ids(request_type_keys)
      request_types = RequestType.where(key: request_type_keys).sort_by { |record| request_type_keys.index(record.key) }

      request_types.map(&:id)
    end

    def find_order_role(role)
      if Rails.env.production?
        OrderRole.find_by!(role:)
      else
        # In development mode or UAT we don't care so much
        OrderRole.find_by(role:) || UatActions::StaticRecords.order_role
      end
    end

    def find_project(name)
      if Rails.env.production?
        Project.find_by!(name:)
      else
        # In development mode or UAT we don't care so much
        Project.find_by(name:) || UatActions::StaticRecords.project
      end
    end

    def find_study(name)
      if Rails.env.production?
        Study.find_by!(name:)
      else
        # In development mode or UAT we don't care so much
        Study.find_by(name:) || UatActions::StaticRecords.study
      end
    end
  end
end
