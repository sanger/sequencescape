# frozen_string_literal: true

module SampleManifestExcel
  module Tags
    module Validator
      ##
      # Uniqueness
      module Uniqueness
        extend ActiveSupport::Concern
        include Tags::ClashesFinder

        included do
          validate :check_tags
        end

        def check_tags
          tag_oligos = upload.data_at(:tag_oligo)
          tag2_oligos = upload.data_at(:tag2_oligo)

          tag_groups = upload.data_at(:tag_group)
          tag_indexes = upload.data_at(:tag_index)
          tag2_groups = upload.data_at(:tag2_group)
          tag2_indexes = upload.data_at(:tag2_index)

          duplicates = if tag_oligos.present? && tag2_oligos.present?
                         find_tags_clash(tag_oligos.zip(tag2_oligos))
                       elsif tag_groups.present? && tag_indexes.present? && tag2_groups.present? && tag2_indexes.present?
                         check_tag_groups_and_indexes(tag_groups, tag_indexes, tag2_groups, tag2_indexes)
                       else
                         {}
                       end
          errors.add(:tags_clash, create_tags_clashes_message(duplicates, FIRST_ROW)) unless duplicates.empty?
        end

        private

        def check_tag_groups_and_indexes(tag_groups, tag_indexes, tag2_groups, tag2_indexes)
          tag_oligos  = []
          tag2_oligos = []
          tag_groups.each_with_index do |grp, index|
            tag_oligos  << TagGroup.find_by(name: grp)&.tags&.find_by(map_id: tag_indexes[index])&.oligo
          end
          tag2_groups.each_with_index do |grp, index|
            tag2_oligos << TagGroup.find_by(name: grp)&.tags&.find_by(map_id: tag2_indexes[index])&.oligo
          end
          find_tags_clash(tag_oligos.zip(tag2_oligos))
        end
      end
    end
  end
end
