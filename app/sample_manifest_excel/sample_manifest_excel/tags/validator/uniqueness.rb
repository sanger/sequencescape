# frozen_string_literal: true

module SampleManifestExcel
  module Tags
    module Validator
      ##
      # Uniqueness
      module Uniqueness
        extend ActiveSupport::Concern
        include Tags::ClashesFinder

        included { validate :check_tags }

        # rubocop:todo Metrics/PerceivedComplexity, Metrics/MethodLength, Metrics/AbcSize
        def check_tags # rubocop:todo Metrics/CyclomaticComplexity
          i7s = upload.data_at(:i7)
          i5s = upload.data_at(:i5)

          tag_groups = upload.data_at(:tag_group)
          tag_indexes = upload.data_at(:tag_index)
          tag2_groups = upload.data_at(:tag2_group)
          tag2_indexes = upload.data_at(:tag2_index)

          duplicates =
            if i7s.present? && i5s.present?
              find_tags_clash(i7s.zip(i5s))
            elsif tag_groups.present? && tag_indexes.present? && tag2_groups.present? && tag2_indexes.present?
              check_tag_groups_and_indexes(tag_groups, tag_indexes, tag2_groups, tag2_indexes)
            else
              {}
            end
          errors.add(:tags_clash, create_tags_clashes_message(duplicates, FIRST_ROW)) unless duplicates.empty?
        end

        # rubocop:enable Metrics/AbcSize, Metrics/MethodLength, Metrics/PerceivedComplexity

        private

        # rubocop:todo Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity, Metrics/AbcSize
        def check_tag_groups_and_indexes(tag_groups, tag_indexes, tag2_groups, tag2_indexes)
          i7s = []
          i5s = []
          tag_groups.each_with_index do |grp, index|
            i7s << TagGroup.find_by(name: grp)&.tags&.find_by(map_id: tag_indexes[index])&.oligo # rubocop:disable Style/SafeNavigationChainLength
          end
          tag2_groups.each_with_index do |grp, index|
            i5s << TagGroup.find_by(name: grp)&.tags&.find_by(map_id: tag2_indexes[index])&.oligo # rubocop:disable Style/SafeNavigationChainLength
          end
          find_tags_clash(i7s.zip(i5s))
        end
        # rubocop:enable Metrics/AbcSize, Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity
      end
    end
  end
end
