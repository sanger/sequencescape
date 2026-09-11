# frozen_string_literal: true

module Api
  module V2
    module Sapio
      module StudySearchQuery
        extend ActiveSupport::Concern

        # The default maximum number of search results allowed to be returned.
        # This can be overridden by passing a custom +maxResults+ parameter in
        # the request context.
        MAX_RESULTS = 20

        class_methods do
          # Applies a name filter to the given records based on the +filter[name]+
          # parameter in the request context. Supports wildcard patterns using
          # '*' and '?' characters, as well as quoted phrases for exact matches.
          # Unquoted wildcards activate the wildcard based search, otherwise
          # exact/partial/phonetic matching is used.
          #
          # @param records [ActiveRecord::Relation] The base study relation to filter.
          # @param _value [String] Not used because JSONAPI:: Resources strips quotes.
          #   We use the request context to get the raw filter value instead.
          # @param options [Hash] The options hash passed to the filter method,
          #   which contains the request context.
          # @return [ActiveRecord::Relation] The filtered study relation.
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
        end

        class_methods do
          # Returns the value of the +filter[name]+ parameter from the request context.
          #
          # @param options [Hash] The options hash passed to the filter method.
          # @return [String] The value of the +filter[name]+ parameter, or an empty string if not present.
          def filter_name(options)
            options.dig(:context, :filter_name).to_s.squish
          end
        end

        class_methods do
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
        end

        class_methods do
          # Splits a query into quoted-phrase and unquoted-chunk tokens.
          # A quoted-phrase token includes its surrounding quotes.
          #
          # @param query [String] The search string, potentially containing quoted phrases.
          # @return [Array<String>] The tokens, in order.
          def tokenize_query(query)
            # "[^"\\]*(?:\\.[^"\\]*)*" : Quoted token
            # |                        : OR
            # [^"]+                    : Unquoted chunk
            query.scan(/"[^"\\]*(?:\\.[^"\\]*)*"|[^"]+/)
          end
        end

        class_methods do
          # Builds a SQL LIKE pattern from the query, supporting:
          # - quoted phrases as literal text
          # - unquoted `*` as `%`
          # - unquoted `?` as `_`
          #
          # Any `%`, `_`, or `\` characters inside literal text are escaped so
          # they are treated as data, not LIKE metacharacters.
          #
          # @param records [ActiveRecord::Relation] The base study relation to filter.
          # @param query [String] The search string, potentially containing quoted
          #   phrases and wildcard characters.
          # @return [ActiveRecord::Relation] A relation filtered by the translated
          #   LIKE pattern.
          def wildcard_name_scope(records, query)
            translated_pattern = tokenize_query(query).map do |token|
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
        end

        class_methods do
          # Strips quote delimiters from every quoted phrase in the query,
          # treating quoted content as literal text wherever it appears (even
          # when only part of the query is quoted, e.g. `MAVE_SGE "v0.2.1"`).
          #
          # @param query [String] The search string, potentially containing quoted phrases.
          # @return [String] The query with quote delimiters removed.
          def strip_quotes(query)
            tokenize_query(query)
              .map { |token| token.start_with?('"') && token.end_with?('"') ? token[1..-2] : token }
              .join
              .squish
          end
        end

        class_methods do
          # Escapes SQL LIKE wildcard and escape characters in a literal string.
          #
          # @param str [String] The string to escape for use in a LIKE pattern.
          # @return [String] The escaped string.
          def sql_escape(str)
            str.gsub(/[%_\\]/) { |char| "\\#{char}" }
          end
        end

        class_methods do
          # Filters studies by name using exact match, partial match, and,
          # where appropriate, phonetic match.
          # Quoted phrases are stripped of their quotes and treated as literal
          # text, even when only part of the query is quoted (e.g.
          # `MAVE_SGE "v0.2.1"`).
          #
          # Phonetic (SOUNDEX) matching is skipped when the whole query is one
          # quoted "exact phrase", and for any query containing digits.
          # MySQL's SOUNDEX() ignores all non-alphabetic characters, so it
          # cannot distinguish names that differ only numerically (e.g.
          # "v0.2.1" vs "v0.3.1"), which would otherwise cause both to match
          # a search for either one.
          #
          # @param records [ActiveRecord::Relation] The base study relation to filter.
          # @param query [String] The search string to match against study names.
          # @return [ActiveRecord::Relation] A relation filtered by exact, partial, or
          #   phonetic name matching.
          def contains_name_scope(records, query)
            quoted = query.start_with?('"') && query.end_with?('"')
            query = strip_quotes(query)
            escaped_query = sql_escape(query)

            condition = 'studies.name = :exact OR ' \
                        "studies.name LIKE :partial ESCAPE '\\\\'"
            condition += ' OR SOUNDEX(studies.name) = SOUNDEX(:query)' unless quoted || query.match?(/\d/)

            records.where(condition, exact: query, partial: "%#{escaped_query}%", query: query)
          end
        end
      end
    end
  end
end
