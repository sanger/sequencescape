# frozen_string_literal: true
# This file was automatically generated via `rails g record_loader`

# RecordLoader handles automatic population and updating of database records
# across different environments
# @see https://rubydoc.info/github/sanger/record_loader/
module RecordLoader
  # Creates the specified submission templates if they are not present
  class SubmissionTemplateLoader < ApplicationRecordLoader
    config_folder 'submission_templates'

    def create_or_update!(section_name, options)
      options['name'] ||= section_name
      derived_options = generate_derived_options(options['related_records'])
      final_options = options.except('related_records').merge(derived_options)

      SubmissionTemplate.create_with(final_options).find_or_create_by!(name: options['name'])
    end

    def generate_derived_options(related_records)
      {
        product_line: ProductLine.find_or_create_by!(name: related_records['product_line_name']),
        product_catalogue: ProductCatalogue.find_by!(name: related_records['product_catalogue_name']),
        submission_parameters: submission_parameters(related_records)
      }
    end

    # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity, Metrics/MethodLength
    def submission_parameters(related_records)
      params = {}
      params[:info_differential] = related_records['info_differential'] if related_records['info_differential']
      if related_records['request_options']
        params[:request_options] =
          decode_request_options(related_records['request_options'])
      end
      params[:asset_input_methods] = related_records['asset_input_methods'] if related_records['asset_input_methods']
      params[:request_type_ids_list] = sort_request_type_ids(related_records['request_type_keys']) if related_records[
        'request_type_keys'
      ]
      params[:input_field_infos] = related_records['input_field_infos'] if related_records['input_field_infos']
      params[:order_role_id] = find_order_role(related_records['order_role']).id if related_records['order_role']
      params[:project_id] = find_project(related_records['project_name']).id if related_records['project_name']
      params[:study_id] = find_study(related_records['study_name']).id if related_records['study_name']
      params
    end

    # rubocop:enable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity, Metrics/MethodLength

    def sort_request_type_ids(request_type_keys)
      request_types = RequestType.where(key: request_type_keys).sort_by { |record| request_type_keys.index(record.key) }

      # For some reason we don't understand this list is stored as an array of arrays in the database,
      # so we need to zip to get it into the right format
      request_types.map(&:id).zip
    end

    def decode_request_options(request_options)
      editied_request_options_hash = {}
      editied_request_options_hash.merge!(decode_request_option_initial_state(request_options))
      # will add more decoding methods here as needed
      editied_request_options_hash
    end

    def decode_request_option_initial_state(request_options)
      return {} unless request_options['initial_state']

      # returns e.g. initial_state: { 8 => :pending }
      {
        initial_state:
          request_options['initial_state']
            .transform_keys { |key| RequestType.find_by!(key:).id }
            .transform_values(&:to_sym)
      }
    end

    def find_order_role(role)
      if Rails.env.production?
        OrderRole.find_or_create_by!(role:)
      else
        # In development mode or UAT we use a static record as backup
        OrderRole.find_or_create_by(role:) || UatActions::StaticRecords.order_role
      end
    end

    def find_project(name)
      if Rails.env.production?
        Project.find_by!(name:)
      else
        # In development mode or UAT we use a static record as backup
        Project.find_by(name:) || UatActions::StaticRecords.project
      end
    end

    def find_study(name)
      if Rails.env.production?
        Study.find_by!(name:)
      else
        # In development mode or UAT we use a static record as backup
        Study.find_by(name:) || UatActions::StaticRecords.study
      end
    end
  end
end
