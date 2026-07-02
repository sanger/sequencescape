# frozen_string_literal: true

module Api
  module V2
    module Sapio
      # Sapio-specific Study resource for Integration Hub consumers.
      #
      # @note The reference_genome relationship on studies is not accurate.
      #   Use the reference_genome relationship on study_metadata instead.
      #
      # @note It does not subclass Api::V2::StudyResource to decouple it from
      #   the default Study resource, which is used by other API consumers.
      class StudyResource < Api::V2::BaseResource
        immutable # Read-only is enough for the Sapio study search story.

        # The default maximum number of search results allowed to be returned.
        # This can be overridden by passing a custom +maxResults+ parameter in
        # the request context.
        MAX_RESULTS = 20

        ###
        # Filters
        ###

        # Override the name filter from parent to support wildcard patterns
        # Accepts patterns like "my_study*" or "my_study?"
        filter :name, apply: method(:apply_name_filter)

        ###
        # Attributes
        ###

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
          # Applies the `name` filter to studies, using either wildcard matching or
          # exact/partial/phonetic matching depending on the query contents.
          #
          # The raw query is read from the request context because JSONAPI strips quotes
          # from the filter value array.
          #
          # @param records [ActiveRecord::Relation] The base study relation to filter.
          # @param _value [Object] Unused JSONAPI filter value.
          # @param options [Hash] The filter options hash, including request context.
          # @return [ActiveRecord::Relation] A filtered relation, or `records.none` when
          #   the query is blank.
          def apply_name_filter(records, _value, options)
            query = filter_name(options)
            return records.none if query.empty?

            max_results = (options.dig(:context, :max_results).presence || MAX_RESULTS).to_i
            relation = if wildcard_query?(query)
              wildcard_name_scope(records, query)
            else
              contains_name_scope(records, query)
            end

            raise Errors::ResultSetTooLarge if relation.limit(max_results + 1).pluck(:id).size > max_results

            relation
          end

          # Returns the value of the +filter[name]+ parameter from the request context.
          #
          # @param options [Hash] The options hash passed to the filter method.
          # @return [String] The value of the +filter[name]+ parameter, or an empty string if not present.
          def filter_name(options)
            options.dig(:context, :filter_name).to_s.squish
          end

          # Returns true if the query contains wildcard characters outside of
          # "quoted phrases" (literal strings). The wildcard characters are '*'
          # and '?'. If the query contains unbalanced quotes, wildcard
          # characters outside any balanced quoted phrase are still treated as
          # wildcards.
          #
          # @example abc* def "ghi*" "jkl?" -> true
          # @example abc "def" "ghi*" "jkl?" -> false
          #
          # @param query [String] The search query to check for wildcards.
          # @return [Boolean] True if the query contains wildcards, false otherwise.
          def wildcard_query?(query)
            query.scan(/"[^"\\]*(?:\\.[^"\\]*)*"|([*?])/).flatten.compact.any?
          end

          # Builds a SQL LIKE pattern from the query, supporting:
          # - quoted phrases as literal text
          # - unquoted `*` as `%`
          # - unquoted `?` as `_`
          #
          # Any `%`, `_`, or `\` characters inside literal text are escaped so they
          # are treated as data, not LIKE metacharacters.
          #
          # @param records [ActiveRecord::Relation] The base study relation to filter.
          # @param query [String] The search string, potentially containing quoted
          #   phrases and wildcard characters.
          # @return [ActiveRecord::Relation] A relation filtered by the translated
          #   LIKE pattern.
          def wildcard_name_scope(records, query)
            # "[^"\\]*(?:\\.[^"\\]*)*" : Quoted token
            # |                        : OR
            # [^"]+                    : Unquoted chunk
            tokens = query.scan(/"[^"\\]*(?:\\.[^"\\]*)*"|[^"]+/)

            translated_pattern = tokens.map do |token|
              if token.start_with?('"') && token.end_with?('"')
                # Inside quotes: strip delimiters, treat content as literal
                sql_escape(token[1..-2])
              else
                # Outside quotes: escape SQL characters, then map * to % and ? to _
                sql_escape(token).tr('*', '%').tr('?', '_')
              end
            end.join

            records.where("studies.name LIKE :pattern ESCAPE '\\\\'", pattern: translated_pattern)
          end

          # Escapes SQL LIKE wildcard and escape characters in a literal string.
          #
          # @param str [String] The string to escape for use in a LIKE pattern.
          # @return [String] The escaped string.
          def sql_escape(str)
            str.gsub(/[%_\\]/) { |char| "\\#{char}" }
          end

          # Filters studies by name using exact match, partial match, and phonetic match.
          # If the query is quoted, the quotes are stripped before matching and the
          # search term is treated as literal text.
          #
          # @param records [ActiveRecord::Relation] The base study relation to filter.
          # @param query [String] The search string to match against study names.
          # @return [ActiveRecord::Relation] A relation filtered by exact, partial, or
          #   phonetic name matching.
          def contains_name_scope(records, query)
            query = query[1..-2].squish if query.start_with?('"') && query.end_with?('"')
            escaped_query = sql_escape(query)
            condition = 'studies.name = :exact OR ' \
                        "studies.name LIKE :partial ESCAPE '\\\\' OR " \
                        'SOUNDEX(studies.name) = SOUNDEX(:query)'
            records.where(condition, exact: query, partial: "%#{escaped_query}%", query: query)
          end
        end
      end
    end
  end
end
