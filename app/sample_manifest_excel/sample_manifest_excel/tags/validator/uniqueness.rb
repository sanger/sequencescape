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
          duplicates = if tag_oligos.present? && tag2_oligos.present?
                         find_tags_clash(tag_oligos.zip(tag2_oligos))
                       else
                         {}
                       end
          errors.add(:tags_clash, create_tags_clashes_message(duplicates, FIRST_ROW)) unless duplicates.empty?
        end
      end
    end
  end
end
