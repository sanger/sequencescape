# frozen_string_literal: true

module Api
  module V2
    module Sapio
      # Sapio-specific Study resource for Integration Hub consumers.
      #
      # @note The reference genome association on the studies are not correct.
      #   Use the reference_genome_id column in the study_metadata table instead.
      #
      class StudyResource < Api::V2::BaseResource
        # @!attribute [r] name
        #   @return [String] The name of the study.
        attribute :name

        # @!attribute [r] uuid
        #   @return [String] The UUID of the study.
        attribute :uuid

        # @!attribute [r] created_at
        #   @return [String] Timestamp when the study was created.
        attribute :created_at

        # @!attribute [r] updated_at
        #   @return [String] Timestamp when the study was last updated.
        #   @note study_metadata association specifies touch: true, so updated_at
        #     will reflect changes to the study_metadata as well.
        attribute :updated_at

        # @!attribute [r] blocked
        #   @return [Boolean] Whether the study is blocked.
        #   @note All rows in production have this column set to false.
        attribute :blocked

        # @!attribute [r] state
        #   @return [String] The state of the study (pending, active, or inactive).
        attribute :state

        # @!attribute [r] ethically_approved
        #   @return [Boolean] Whether ethical approval is set.
        attribute :ethically_approved

        # @!attribute [r] enforce_data_release
        #   @return [Boolean] Whether data release enforcement is enabled.
        attribute :enforce_data_release

        # @!attribute [r] enforce_accessioning
        #   @return [Boolean] Whether accessioning enforcement is enabled.
        attribute :enforce_accessioning

        # @!attribute [r] study_metadata
        #   @return [StudyMetadataResource] The metadata associated with this
        #     study, containing additional details like faculty sponsor
        has_one :study_metadata, class_name: 'StudyMetadata', foreign_key_on: :related

        # @!attribute [r] user
        #   @return [UserResource, nil] The user associated with this study.
        has_one :user, class_name: 'User', foreign_key_on: :self

        class << self
          def apply_name_filter(records, value, _options)
            query = normalize_name_filter(value)
            return records.none if query.empty?

            wildcard_query?(query) ? wildcard_name_scope(records, query) : fuzzy_name_scope(records, query)
          end

          def normalize_name_filter(value)
            query = (value.is_a?(Array) ? value.first : value).to_s.strip
            query.delete_prefix('"').delete_suffix('"')
          end

          def wildcard_query?(query)
            query.include?('*') || query.include?('?')
          end

          def wildcard_name_scope(records, query)
            pattern = query
              .gsub('\\', '\\\\')
              .gsub('%', '\\%')
              .gsub('_', '\\_')
              .tr('*', '%')
              .tr('?', '_')
            records.where("studies.name LIKE :pattern ESCAPE '\\\\'", pattern:)
          end

          def fuzzy_name_scope(records, query)
            escaped_query = query.gsub(/[%_\\]/) { |char| "\\#{char}" }
            condition = 'studies.name = :exact OR ' \
                        "studies.name LIKE :partial ESCAPE '\\\\' OR " \
                        'SOUNDEX(studies.name) = SOUNDEX(:query)'
            records.where(condition, exact: query, partial: "%#{escaped_query}%", query: query)
          end
        end

        ###
        # Filters
        ###

        # Override the name filter from parent to support wildcard patterns
        # Accepts patterns like "my_study*" or "my_study?"
        filter :name, apply: method(:apply_name_filter)
      end
    end
  end
end
