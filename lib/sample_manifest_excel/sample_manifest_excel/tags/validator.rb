module SampleManifestExcel
  module Tags
    # TODO: A bit of abstraction to make this suitable for other users.
    module Validator
      module Uniqueness
        extend ActiveSupport::Concern
        include Tags::ClashesFinder

        included do
          validate :check_tags
        end

        # it happens for every row now. Probably it should not.
        def check_tags
          tag_oligos = upload.data_at(:tag_oligo)
          tag2_oligos = upload.data_at(:tag2_oligo)
          duplicates = find_tags_clash(tag_oligos.zip(tag2_oligos)) if tag_oligos.present? && tag2_oligos.present?
          unless duplicates.empty?
            errors.add(:tags_clash, create_tags_clashes_message(duplicates, FIRST_ROW))
          end
        end
      end

      module Formatting
        extend ActiveSupport::Concern

        included do
          validate :check_formatting
        end

        def check_formatting
          if value.present?
            unless value.match?(/\A[acgtACGT]+\z/)
              errors.add(:tag, 'must be a combination of A,C,G and T')
            end
          end
        end
      end
    end
  end
end
